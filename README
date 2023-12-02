### Objective


The codebase is modified in order to add a new system call, trace, and an accompanying user program strace.


`strace mask command [args]`

strace runs the specified command until it exits.
- It intercepts and records the system calls which are called by a process
during its execution.
- It should take one argument, an integer mask, whose bits specify which
system calls to trace.


For example, to trace the i" system call, a program calls strace 1<<*i*, where *i* is the syscall number (in kernel/syscall.h).

The xv6 kernel is modified to print out a line when each system call is about to return if the system calls number is set in the mask.

The line contains:
1. The process id
2. The name of the system call
3. The decimal value of the arguments (xv6 passes arguments via registers)
4. The return value of te syscall

For example:

`$ strace 32 grep hello README`
outputs

`6: syscall read (3 2736 1023) -> 1023`
`6: syscall read (3 2793 966) -> 966`
`6: syscall read (3 2764 995) -> 70`
`6:syscall read (3 2736 1023) -> 0`

### Brief Implementation details

The implemented syscall trace essentially (when a syscall is being called) prints out the id of the process calling it, the name of the syscall, its arguments and return value.
The trace syscall sets various variables of the process calling it appropriately so that it is traced, and then exec is run. A new property is_trace has been added to the structure proc to indicate whether a process should be traced, and new arrays syscall_args, syscall_returns and syscall_ids have been added as elements of the process to hold the corresponding vales of all syscalls of the process. When the process is sbout to exit, if is_trace is 1, then the values in the arrays are printed appropriately. Default values of the variables are set in proc_alloc. 'Mask' has also been added as an element of the structure to hold the argument passed to trace.
