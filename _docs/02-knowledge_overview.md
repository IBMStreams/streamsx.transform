---
title: "Optimizing Streams Applications"
permalink: /docs/knowledge/overview/
excerpt: "Optimizing Streams Applications"
last_modified_at: 2020-08-20T11:37:48-04:00
redirect_from:
   - /theme-setup/
sidebar:
   nav: "knowledgedocs"
---
{% include toc %}
{% include editme %}


1. Compile with -a.
1. Fuse operators into the same PE to reduce communication costs.
1. Insert threaded ports into PEs to increase throughput through pipeline parallelism. Prefer threaded ports over PEs to obtain pipeline parallelism.
1. Use multiple PEs in an application to take advantage of multiple hosts.
1. Use one PE per host. If there are two PEs on the same host, they should probably be fused into one PE. Insert threaded ports to regain parallelism.
1. Improve the performance of bottlenecks to improve the throughput of an application. Trying to improve the performance of an application without knowing who is the bottleneck is a waste of time. When a parallel region is no longer the bottleneck, further parallelism will not help.
1. Know your hardware. Distribute PEs to hosts so as to avoid over-subscribing any resource (cores, memory, disk, etc.) on that host.



