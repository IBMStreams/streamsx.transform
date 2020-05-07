# streamsx.transform
This toolkit contains general-purpose operators that do tuple manipulation.  Currently, the only operator it contains is Modify, but operators that perform joins and aggregations fit would fit in this toolkit.

General-purpose operators that perform manipulations on streams without looking at the tuples should go into streamsx.plumbing. 

## Modify

The Modify operator can be used as a replacement for Functor when the input types and output types are the same.   For large tuples, using Modify may improve performance, and will never hurt performance.  

Functor creates a new output tuple from the input tuple, while Modify modifies the input tuple and place it on the output stream.  When tuples are large and the modification is small, Functor can result is a lot of data copying, which can impact performance.  


As an example, consider application in tests/timing.  The application applies Functor or Modify three times in a row on the input tuple, incrementing one attribute each time.  The input tuple has three attributes, one of which is a list.  When the list is small, there is little difference between `Functor` and `Modify`.  When the list is large, the performance difference can be quite large.  Here's some numbers from a run on my machine: 

| Operator | list size 1 | list size 100 |
-----------|-------------|---------------|
Modify     |    18.8s    | 23.8s         |
Functor    |    22.8s    | 123s          |



## Using the Modify Operator to Reduce Copying
We've made the `Modify` operator available as part of [streamsx.transform](http://ibmstreams.github.io/streamsx.transform/) on Github. It is used like Functor, but unlike Functor, it modifies its input tuple rather than creating a new one. Because it submits the same tuple it received, it's limited to the case where the input type and output type are the same. Because it doesn't copy tuple attributes, using `Modify` instead of `Functor` can speed up your application, especially when your tuple size is large and the application uses `partitionColocation` statements. The first your first step in optimizing your application is to go [here](https://developer.ibm.com/streamsdev/2014/09/07/optimizing-streams-applications/). Trying to eliminate extra copies should only come after the more basic steps described there. The rest of this post dives into the guts of Streams to explain why this can make a difference, and why we had to create a separate operator rather than modifying `Functor`.

## Functor vs Filter

Let me start by looking at `Functor`. `Functor` lets you transform one tuple into another, and it also comes with a filter parameter to let you drop tuples you don't want to pass through. Let's say your input tuple and output tuple are the same, but you just want to filter out some of them. You could use a `Functor`:

<pre>stream<Data> Filtered = Functor(Data) {
    param filter: x > 5;
}
</pre>

or you could use a `Filter`

<pre>stream<Data> Filtered = Filter(Data) {
   param filter: x > 5;
}
</pre>

Let's pause for a moment. What's the difference between the two? While the two snippets look very similar, the generated C++ is different. From Filter, notice that the input tuple itself is submitted:

<pre>    IPort0Type const & iport$0 = static_cast<IPort0Type const &>(tuple);
    if (lit$0)
        submit(tuple, 0);
</pre>

From Functor, notices that a new tuple is created, and the new tuple is submitted:

<pre>    IPort0Type const & iport$0 = static_cast<IPort0Type const &>(tuple);
    if (!(lit$0) )
        return;
    { OPort0Type otuple(iport$0); submit(otuple, 0); }
</pre>

The difference is Filter operator passes on the same tuple it received, while the `Functor` makes a new tuple. When the operator is connected to its downstream operator via a partition colocation statement (or because they are in a standalone) and the the tuple size is large, the `Functor` is much more expensive because it is copying every attribute in the tuple, while `Filter` is not. I measured this performance difference for input tuple containing a list of 100 integers where the filter expressions were true. The `Filter` is about three times as as fast `Functor`--for 100,000,000 tuples, about 17 seconds for `Filter` and 45 for `Functor`. `Modify` came out of a desire to have an operator that could be used like `Functor` but didn't create new tuples.

## Introducing `Modify`

To speed up the case when the tuples are large and only a small change is being made, I created the `Modify` operator. It's used exactly like the `Functor`, except that its input type and output type must be the same. Internally, though, unlike `Functor` it modifies the input tuple in place and then sends it on. Let's say we write something like this:

<pre>stream<Data> Increment = Modify(Data) {
output Increment:
   x = x +1;
}

Here's Modify:</pre>

<pre>       iport$0.set_x(SPL::int32(iport$0.get_x() + lit$0)); 
       submit(iport$0,0);
</pre>

from an equivalent use of Functor. Note the newly created otuple.

<pre>    OPort0Type otuple(SPL::int32(iport$0.get_x() + lit$0), iport$0.get_lotsOfData()); 
    submit (otuple, 0);
</pre>

In my quick test, this can result in a significant performance improvement for large tuple sizes--23 seconds for `Modify` versus 45 seconds for `Functor`. The next section is where we really dive into the guts of Streams.

### Why do we need a new operator?

It is tempting to think we can add this modify-in-place capability to `Functor`--that is, if the input type and output type are the same, generate code for `Modify`, and otherwise, generate code as it does now. This would give us one operator that works like `Modify` when input and output types are the same, and `Functor` otherwise. But doing this would actually slow down applications in some circumstances, and to explain why, I'm going to have to describe a feature of the Streams runtime you've probably been using but may never have noticed. Consider the following application:

<pre>stream<int32 x,int32 y> Data = Beacon() {
output Data:
   x = 0,y=0;
}

streams<int32 x,int32 y> IncrX = Modify(Data) {
output IncrX:
    x=x+1;
}

streams<int32 x,int32 y> IncrY = Modify(Data) {
   output IncrY: 
      y=y+1;
} 
</pre>

You'd expect that all the tuples on IncrX stream have `x=1` and `y=0` and that all the tuples on the IncrY stream have `x=0` and `y=1`. When the `Beacon` is in a different PE than `IncrX` and `IncrY`, the tuple from the `Beacon` is copied to `IncrX` and `IncrY`. But when we use `partitionColocation` to put them inside a shared PE, or when its run in standalone mode, tuples are passed by reference between operators. To ensure this doesn't result in the same tuple being changed by IncrX and IncrY, in order to prevent the output from having a tuple with both x and y incremented, the SPL runtime needs to make a copy of the tuples on the Data stream, to ensure that the same C++ object isn't sent to both `IncrX` and `IncrY`. But now let's look at that same app with `Functor` instead of `Modify`:

<pre>composite NoRuntimeCopy {

graph
stream<int32 x,int32 y> Data = Beacon() {
output Data:
   x = 0,y=0;
}

streams<int32 x,int32 y> IncrX = Functor(Data) {
output IncrX:
    x=x+1;
}

streams<int32 x,int32 y> IncrY = Functor(Data) {
   output IncrY: 
      y=y+1;
} 
}
</pre>

In this case, the SPL runtime does NOT need to copy the tuples on the Data stream. Since `Functor` does not modify its input tuples, it can send the same tuple to `IncrX` and to `IncrY`, and there won't be a tuple with `x==1` and `y==1`. And, in fact, the SPL runtime does not make a copy in this case, and uses the same tuple. This brings up the question: How does the SPL runtime know whether it's dealing with an operator like `Modify` for which it needs to make a copy, or an operator like `Functor`? To do make that decision, it uses the operator model. Remember that that operator model is the same for all invocations of the operator, no matter its input or output tuples. One of the properties of an input port in the operator model is `tupleMutationAllowed`. If we allow `Functor` to sometimes change its input tuple, then we'd have to change the tuple mutation allowed to be true, and the runtime wouldn't know when it was safe to skip a copy, and we'd do extra copying in some cases. As far as the SPL runtime is concerned, there's one big difference between `Functor` and `Modify`: `Functor` agrees not to change or update its input, but `Modify` makes no such promises.

## Final notes

This post can be summed as use `Modify` instead of `Functor` when your input and output types are the same. But the broader message here is to be aware of when the Streams runtime and operators are copying tuples. This post is actually a simplification; the SPL runtime uses more information than just the `tupleMutationAllowed` attribute to decide whether a copy is necessary. See [here](https://www.ibm.com/support/knowledgecenter/nl/SSCRJU_4.0.0/com.ibm.streams.dev.doc/doc/str_portmutability.html) for details.


