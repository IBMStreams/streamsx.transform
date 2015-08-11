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






