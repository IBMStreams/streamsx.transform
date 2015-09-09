toolkit=../../../com.ibm.streamsx.transform
opts=-a
iterations=60000000
sc $opts -T -M StringListBasic_String1 String1 '\"malfoy\" in potterList' -t $toolkit
time output/bin/standalone iterations=$iterations
sc $opts -T -M StringListDynamic_String1 String1 '\"malfoy\" in potterList' -t $toolkit
time output/bin/standalone iterations=$iterations
sc $opts -T -M IntDynamic_1 1 'x > 5l' -t $toolkit
time output/bin/standalone iterations=$iterations
sc $opts -T -M IntBasic_1 1 'x > 5l' -t $toolkit
time output/bin/standalone iterations=$iterations
sc $opts -T -M StringEqualityBasic_1 1 'heroine==\"Lizzy\"' -t $toolkit
time output/bin/standalone iterations=$iterations
sc $opts -T -M StringEqualityDynamic_1 1 'heroine==\"Lizzy\"' -t $toolkit
time output/bin/standalone iterations=$iterations
