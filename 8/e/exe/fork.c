#include "proc.h"
#include "exe.h"
#include "mm.h"
#include "sysconst.h"
#include "global.h"
#include "stdio.h"
#include "stdlib.h"
#include "string.h"
#include "protect.h"

uint32_t alloc_mem(size_t size);

uint32_t fork()
{
	struct message msg;
	msg.value = FORK;

	sendrecv(BOTH, PID_TASK_EXE, &msg);
	assert(msg.RETVAL == 0);

	return msg.FORK_PID;
}

uint32_t do_fork()
{
	/* find a free slot in proc_table[] */
	struct proc* p_proc;
	uint32_t child_pid = NONE;
	for (p_proc = &FIRST_PROC; p_proc <= &LAST_PROC; p_proc++) 
	{
		if (p_proc->flag == FREE_SLOT) 
		{
			child_pid = p_proc - &FIRST_PROC;
			break;
		}
	}
	/* 此时 p_proc 指向子进程 */
	if (child_pid == NONE) 
	{
		printf("\n#ERROR#-do_fork: no free slot in proc_table[]");
		return -1;
	}

	/* Duplicate the process table */
	uint32_t pid = exe_msg.source;
	uint16_t child_ldt_sel = p_proc->ldt_selector;
	memcpy(p_proc, &proc_table[pid], sizeof(struct proc));
	proc_table[child_pid].pid = child_pid;
	proc_table[child_pid].pid_parent = pid;
	proc_table[child_pid].ldt_selector = child_ldt_sel;
	
	/* Duplicate text segment, data segment */
	uint8_t* p_desc;
	
	/* Text segment */
	p_desc = &proc_table[pid].LDT[INDEX_LDT_C * DESC_SIZE];
	uint32_t caller_T_base = get_base(p_desc);
	uint32_t caller_T_limit = get_limit(p_desc);
	uint32_t caller_T_size = (caller_T_limit + 1) * granularity(p_desc);

	/* Data segment */	
	p_desc = &proc_table[pid].LDT[INDEX_LDT_RW * DESC_SIZE];
	uint32_t caller_D_base = get_base(p_desc);
	uint32_t caller_D_limit = get_limit(p_desc);
	uint32_t caller_D_size = (caller_D_limit + 1) * granularity(p_desc);
	
	/* Allocate memory for child process */
	assert(caller_T_size > 0);
	uint32_t child_base = alloc_mem(caller_T_size);
	
	vm_free((void*) child_base, caller_T_size);
	
	assert(child_base != NULL);
	assert((caller_T_base == caller_D_base) &&
	       (caller_T_limit == caller_D_limit) &&
	       (caller_T_size == caller_D_size));
		
	p_current_proc = proc_table + child_pid;

	memcpy((void*) child_base, (void*) caller_T_base, caller_T_size);

	/* child's LDT */
	init_desc(&p_proc->LDT[INDEX_LDT_C * DESC_SIZE],
		  child_base,
		  PROC_IMAGE_SIZE - 1,
		  DA_C32 | DPL_3);
	
	init_desc(&p_proc->LDT[INDEX_LDT_RW * DESC_SIZE],
		  child_base,
		  PROC_IMAGE_SIZE - 1,
		  DA_D32 | DPL_3);
	
	/**
	 * Parent is calling `fork()`, which takes `exe_msg.FORK_PID` as its
	 * return-value. Therefore parent will get PID of its child.
	 */
	exe_msg.FORK_PID = child_pid;
	
	/**
	 * Child is a copy of its parent, which is calling `fork()`. Therefore
	 * child will be also calling `fork()`, and the return-value getting from
	 * `fork()` will be zero, which specifies its identification as a child.
	 */
	struct message msg;
	msg.RETVAL = 0;
	msg.FORK_PID = 0;
	sendrecv(SEND, child_pid, &msg);
	
	return 0;
}

uint32_t alloc_mem(size_t size)
{
	return (uint32_t)vm_alloc(NULL, size, PAGE_READWRITE);
}

