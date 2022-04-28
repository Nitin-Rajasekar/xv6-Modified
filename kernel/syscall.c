#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "syscall.h"
#include "defs.h"
#include "fcntl.h"
//#include "user/user.h"

// Fetch the uint64 at addr from the current process.
int fetchaddr(uint64 addr, uint64 *ip)
{
  struct proc *p = myproc();
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz)
    return -1;
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    return -1;
  return 0;
}

// Fetch the nul-terminated string at addr from the current process.
// Returns length of string, not including nul, or -1 for error.
int fetchstr(uint64 addr, char *buf, int max)
{
  struct proc *p = myproc();
  int err = copyinstr(p->pagetable, buf, addr, max);
  if (err < 0)
    return err;
  return strlen(buf);
}

static uint64
argraw(int n)
{
  struct proc *p = myproc();
  switch (n)
  {
  case 0:
    return p->trapframe->a0;
  case 1:
    return p->trapframe->a1;
  case 2:
    return p->trapframe->a2;
  case 3:
    return p->trapframe->a3;
  case 4:
    return p->trapframe->a4;
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}

// Fetch the nth 32-bit system call argument.
int argint(int n, int *ip)
{
  *ip = argraw(n);
  return 0;
}

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int argaddr(int n, uint64 *ip)
{
  *ip = argraw(n);
  return 0;
}

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
  uint64 addr;
  if (argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
}

extern uint64 sys_chdir(void);
extern uint64 sys_close(void);
extern uint64 sys_dup(void);
extern uint64 sys_exec(void);
extern uint64 sys_exit(void);
extern uint64 sys_fork(void);
extern uint64 sys_fstat(void);
extern uint64 sys_getpid(void);
extern uint64 sys_kill(void);
extern uint64 sys_link(void);
extern uint64 sys_mkdir(void);
extern uint64 sys_mknod(void);
extern uint64 sys_open(void);
extern uint64 sys_pipe(void);
extern uint64 sys_read(void);
extern uint64 sys_sbrk(void);
extern uint64 sys_sleep(void);
extern uint64 sys_sleep(void);
extern uint64 sys_trace(void);
extern uint64 sys_unlink(void);
extern uint64 sys_wait(void);
extern uint64 sys_waitx(void);
extern uint64 sys_write(void);
extern uint64 sys_uptime(void);

static uint64 (*syscalls[])(void) = {
    [SYS_fork] sys_fork,
    [SYS_exit] sys_exit,
    [SYS_wait] sys_wait,
    [SYS_pipe] sys_pipe,
    [SYS_read] sys_read,
    [SYS_kill] sys_kill,
    [SYS_exec] sys_exec,
    [SYS_fstat] sys_fstat,
    [SYS_chdir] sys_chdir,
    [SYS_dup] sys_dup,
    [SYS_getpid] sys_getpid,
    [SYS_sbrk] sys_sbrk,
    [SYS_sleep] sys_sleep,
    [SYS_uptime] sys_uptime,
    [SYS_open] sys_open,
    [SYS_write] sys_write,
    [SYS_mknod] sys_mknod,
    [SYS_unlink] sys_unlink,
    [SYS_link] sys_link,
    [SYS_mkdir] sys_mkdir,
    [SYS_close] sys_close,
    [SYS_waitx] sys_waitx,
    [SYS_trace] sys_trace};

void syscall(void)
{
  int num;
  struct proc *p = myproc();
  num = p->trapframe->a7;
  int arg_holder;
  /*if (trace_enable == 1)
  {
    printf("ID IS %d ", p->pid);

    printf("N IS %s ", num_to_name(num, string));

    p->syscall_ids[p->syscall_index] = num;

    p->syscall_index = p->syscall_index + 1;
  }*/

  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
  {

    int args = 0;
    args = num_arg(num, args);
    for (int i = 0; i < args; i++)
    {
      argint(i, &arg_holder);
      p->syscall_args[p->syscall_index][i] = arg_holder;
    }

    p->trapframe->a0 = syscalls[num]();

    int j;
    int array[100];
    for(int k=0;k<100;k++)
    {
      array[k]=0;
    }
    
    //printf("MASK is %d %d %d\n", p->pid,p->mask, p->is_trace);
    int mask_temp=p->mask;

    for (j = 0; p->mask > 0; j++)
    {
      array[j] = p->mask % 2;
      p->mask = p->mask / 2;
    }
    p->mask=mask_temp;

    /*for (j = j - 1; j >= 0; j--)
    {
      printf("%d\n", array[j]);
    }*/

    //if (trace_enable == 1 && num != 23 && array[num] == 1)
    //printf("%d syscall num OUTSIDE is %d\n",trace_enable,num);

    if (p->is_trace == 1 && array[num] == 1)

    {

      p->syscall_ids[p->syscall_index] = num;

      p->syscall_returns[p->syscall_index] = p->trapframe->a0;

      //printf("syscall %s ", num_to_name(num, string));

      p->syscall_index++;

      /*
      argint(0, &arg_holder);

      printf("Argument 0 is %d\n", arg_holder);
      argint(1, &arg_holder);

      printf("Argument 1 is %d\n", arg_holder);
      argint(2, &arg_holder);

      printf("Argument 2 is %d\n", arg_holder);
      argint(3, &arg_holder);

      printf("Argument 3 is %d\n", arg_holder);
      argint(4, &arg_holder);

      printf("Argument 4 is %d\n", arg_holder);
      */
    }
  }
  else
  {

    printf("%d %s: unknown sys call %d\n",
           p->pid, p->name, num);
    p->trapframe->a0 = -1;
  }
}

char *n_strcpy(char *dest, char const *src)
{

  char *ptr = dest;

  while ((*dest++ = *src++))
    ;

  return ptr;
}

char *num_to_name(int num, char *string)
{
  switch (num)
  {
  case 1:
    n_strcpy(string, "fork");
    break;
  case 2:
    n_strcpy(string, "exit");
    break;
  case 3:
    n_strcpy(string, "wait");
    break;
  case 4:
    n_strcpy(string, "pipe");
    break;
  case 5:
    n_strcpy(string, "read");
    break;
  case 6:
    n_strcpy(string, "kill");
    break;
  case 7:
    n_strcpy(string, "exec");
    break;
  case 8:
    n_strcpy(string, "fstat");
    break;
  case 9:
    n_strcpy(string, "chdir");
    break;
  case 10:
    n_strcpy(string, "dup");
    break;
  case 11:
    n_strcpy(string, "getpid");
    break;
  case 12:
    n_strcpy(string, "sbrk");
    break;
  case 13:
    n_strcpy(string, "sleep");
    break;
  case 14:
    n_strcpy(string, "uptime");
    break;
  case 15:
    n_strcpy(string, "open");
    break;
  case 16:
    n_strcpy(string, "write");
    break;
  case 17:
    n_strcpy(string, "mknod");
    break;
  case 18:
    n_strcpy(string, "unlink");
    break;
  case 19:
    n_strcpy(string, "link");
    break;
  case 20:
    n_strcpy(string, "mkdir");
    break;
  case 21:
    n_strcpy(string, "close");
    break;
  case 22:
    n_strcpy(string, "waitx");
    break;
  case 23:
    n_strcpy(string, "trace");
    break;
  }
  return string;
}

int num_arg(int num, int args)
{
  switch (num)
  {
  case 1:
    args = 0;
    break;
  case 2:
    args = 1;
    break;
  case 3:
    args = 1;
  case 4:
    args = 1;
    break;
  case 5:
    args = 3;
    break;
  case 6:
    args = 1;
    break;
  case 7:
    args = 2;
    break;
  case 8:
    args = 2;
    break;
  case 9:
    args = 1;
    break;
  case 10:
    args = 1;
    break;
  case 11:
    args = 0;
    break;
  case 12:
    args = 1;
    break;
  case 13:
    args = 1;
    break;
  case 14:
    args = 0;
    break;
  case 15:
    args = 2;
    break;
  case 16:
    args = 3;
    break;
  case 17:
    args = 3;
    break;
  case 18:
    args = 1;
    break;
  case 19:
    args = 2;
    break;
  case 20:
    args = 1;
    break;
  case 21:
    args = 1;
    break;
  case 22:
    args = 3;
    break;
  case 23:
    args = 1;
    break;
  }
  return args;
}
