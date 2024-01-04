#####################################################
# Company:        National University of Defense Technology
# Engineer:       Hu An
# 
# Create Date:    2023/11/09 20:33:32
# Design Name:    test.s
# Target Arch:    RV32G
# Description:    
#                 M-text(PA): 0x80000000
#                 S-text(PA): 0x80000000
#                       (VA): 0x80000000
#                 U-text(PA): 0x80000000
#                       (VA): 0x80000000
#                 T-addr(PA): 0x13000000
#                       (VA): 0x80001000
#                     1st-PT: 0x80000000
#                  2rd-PT(S): 0x80000000
#                  2rd-PT(U): 0x80000000
#####################################################

.section .text
.global _start

_start:
machine:
    csrw    satp, zero      # disable virtual addressing
    la      t0, m_trap
    csrw    mtvec, t0       # trap function in M-status is $(m_trap)
    li      t0, 0x800
    csrw    mstatus, t0     # set MPP=0x1(S-status)
    la      t0, supervisor
    csrw    mepc, t0        # return address from M-status is (VA)/(PA)

    # load 1st page-table
    li      t0, 0x80000800 # t0 = (first_pt_addr)  
    li      t1, 0x20000011 # t1 = (first_pte) [PPN,0x000] = 0x80000000(second-PT address)
    sw      t1, 0(t0)      # store first_pte in (first_pt_addr) 
    # load supervisor 2rd page-table
    li      t0, 0x80000000 # t0 = (second_s_pt_addr)  
    li      t1, 0x200000ef # [PPN,0x000] = 0x80000000
    sw      t1, 0(t0)      # store leaf_s_pte in (second_s_pt_addr)
    # load TUBE 2rd page-table
    li      t0, 0x80000004
    li      t1, 0x04c00000 # [PPN,0x000] = 0x13000000(TUBE space - va[0x80001000]) 触发page fault
    sw      t1, 0(t0) 
 
    # enable virtual addressing
    li      t0, 0x80080000 # [PPN,0x000] = 0x80000000(first-PT address)
    csrw    satp, t0

    mret

m_trap:
    # !
    # ! DO NOT USE t0~t2 in m_trap, the original value in t0~t2 in U-status will be overwriten
    # !    
    # process instruction page-fault
    instruction_page_fault:
    li      t3, 0x80000004 # t3 = (second_u_pt_addr)  
    li      t4, 0x04c000ff # [PPN,0x000] = 0x80000000(user va/pa)
    sw      t4, 0(t3)      # store leaf_u_pte in (second_u_pt_addr) 
    mret

supervisor:
    # set return address from S-status be $(user)(va/pa)
    la      t0, user
    csrw    sepc, t0
    sret

user:	
    # send pass_msg to TUBE
    li      t0, 0x80001000  # load TUBE(va)
    addi    t1,zero,0x50    # 'P'
    sb      t1, 0(t0)
    addi    t1,zero,0x41    # 'A'
    sb      t1, 0(t0)
    addi    t1,zero,0x53    # 'S'
    sb      t1, 0(t0)
    addi    t1,zero,0x53    # 'S'
    sb      t1, 0(t0)
    addi    t1,zero,0x0a    # '\n'
    sb      t1, 0(t0)
    # send CTRL+D to TUBE to indicate finish test
    _finish:
    li      t1, 0x4         # 0x4(ASCII: EOT(end of transmission))
    sb      t1, 0(t0)
    beq     zero, zero, _finish



