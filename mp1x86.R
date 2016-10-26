# location 0, on_char 2, off-char 3, on_length 4, off_length 6,countdown 8, status 10, next 12
# mp1_list_head
mp1_ioctl_find: 
# takes long arg location as its parameter
xorl %ebx, %ebx # clear ebx
movl mp1_list_head, %ebx # we load the head pointer to ebx 
cmp $0, %ebx # in order to see if the list is empty
xorl %ebx, %ebx # clear ebx
xorl %ecx, %ecx # clear ecx
xorl %edx, %edx # clear edx
movl 4(%esp),%edx		 #put the arg parameter into edx register (the user space struct)
cmp $0, %edx    # is the pointer NULL?
je FIND_ERROR
movw (edx), %bx  # extract the location information from struct into BX
pushl %edx    # save registers
pushl %ecx   #that might get clobered
pushw %bx  # push the location at the parameter for the location finder function belows
call list_location_finder #(clobbers eax)  # call the function that points to the found struct
popw %bx  # pop out the parameter
popl %ecx
popl %edx
cmp $0, %eax # did the function return a null pointer?
je FIND_ERROR # if so, no match found, return -1 
# copy eax address into edx address (kernel to user space) using mp1_copy_to_user
pushl $16 # push 16 bytes as 3rd parameter for mp1_copy_to_user 
pushl %eax # push the from address of the sctruct in the list
pushl %edx # push the to address in user space
call mp1_copy_to_user  # copy the matched struct in the list to user space
popl %edx # pop out the to address
popl %ecx # pop out the from address of the struct in the list
addl $4, %esp # pop out the "16" argument
cmp $0, %eax # see if the copy succeeded  (returns 0 bytes)
jne FIND_ERROR # if not, thats an error
movl $0, %eax # if success, therefore return 0 



FIND_ERROR:
movl $-1, %eax # return -1 if there is an error
ret
#---------------------------LIST_LOCATION_FINDER-------------------------------------------------
# assume that the location is in EBX
list_location_finder:
movw 4(%esp), %bx # put the location to match into bx
movl mp1_list_head, %eax # put the mp1 head pointer into eax
cmp $0,%eax # is the list empty?
je END_OF_LIST #if so, there is no match.
LOOP: 
movw (%eax), %cx # put the location at the selected linked struct into cx
cmp %cx, %bx # are the 2 locations equal?
je MATCH # they are, its a match 
movl 12(%eax) ,%ecx  # check if the NEXT pointer is null 
cmp $0, %ecx # is the pointer NULL?
je END_OF_LIST # if so, this is the end of the list traversal
movl %ecx,%eax # set next pointer as curr pointer 
jmp LOOP # redo process for next struct 
ret

END_OF_LIST:
movl $-1, %eax # no result was found, return 
ret

MATCH:
ret
#-------------------------------------------------------------------------------------


mp1_rtc_tasklet:
# walk down list, examing each struct, decrement countown
# if countdown is at 0 after dec, examine status, if status is 1(on_char) if 0, has off_char 
# so put the opposite charcter with a call to mp1_poke. Update coundown field
#return once it reaches end of list.
# ECX used as current pointer, #ebx will be used for calculations, #edx will be used for next address
#---------------------------CHECK IF EMPTY LIST----------------------------------------
xorl %ebx,%ebx # clear ebx
movl mp1_list_head, %ecx #put the address that the pointer points to 
cmp $0,%ecx    	#check if the list pointer points to anything
je FINISH 		# in this case, the list is empty, so return
#---------------------------LIST LOOP---------------------------------------------------
# ecx has the curr pointer, #ebx is used for calc?
TASKLET_LOOP:
movw 8(%ecx), %bx # puts the countdown field into bx
addw $-1, %bx  # decrement the countdown value
pushl %ecx     #save the curr pointer in case...
cmp $0, %bx	     #check if countdown has gone to 0
je SWITCH     #if so, go to switch machanism (clobbers ebx, eax and edx)
movw %bx, 8(%ecx) # move back the decremented countdown value if the countdown hasn't reached 0 yet
#------------------------MOVE POINTER TO THE NEXT STRUCT IF THERE IS ONE--------------------------------
RET_FROM_SWITCH:
popl %ecx   # put back the curr pointer in case its been used
xorl %ebx,%ebx
xorl %edx,%edx
movl 12(%ecx), %edx # put the NEXT address into EDX
cmp $0, %edx  # is there no next struct?
je finish_tasklet # if there isn't anything else in the list, finish the tasklet.
movl %edx, %ecx # make the NEXT field (stored in edx) the new curr address MISTAKE?
jmp TASKLET_LOOP # jump back to the next struct to deal with
finish_tasklet:
ret
#-----------------------------CODE TO TOGGLE ON/OFF MODE IF COUNTDOWN IS AT 0-----------------------------
#   ECX is still used as the struct pointer 
SWITCH:
xorl %ebx, %ebx # set ebx to zero (thats fine)
xorl %eax,%eax  # eax is reset to zero
xorl %edx,%edx # edx is reset to zero
# first, examine status if its 1, change to 0 and off_char, if its 0, change to 1 and on_char
movw 10(%ecx), %bx  # put the status into bx
cmp $0, %bx # is status=0?
je ZERO_TO_ONE #if status=0, do procedure to change it to one
jmp ONE_TO_ZERO # else if status=1, do procedure to change it to 0
# NOTE: both jumps will clobber ebx and edx, but in this case we dont have to worry about it
 

#-----------------------OFF MODE TO ON MODE (0 --> 1) AND MP1_POKE---------------------------------
ZERO_TO_ONE:
xorl %ebx,%ebx  #clear ebx
movw $1, 10(%ecx) # update STATUS to one       UPDATES STATUS!
movw 4(%ecx), %bx # move the "ON_LENGTH" into bx
movw %bx, 8(%ecx)  # move ON_LENGTH into countdown      UPDATES THE COUNTDOWN
xorl %ebx,%ebx # clear ebx again
movw (%ecx), %bx  # put location offset into bx
movl %ebx, %eax  # set the offset parameter for mp1_poke
movb 2(%ecx), %dl  # put on char into dl
xorl %ecx,%ecx  # clears ecx :( 
movb %dl, %cl # move the on char into cl for mp1_poke
call mp1_poke
jmp RET_FROM_SWITCH
#-----------------------ON MODE TO OFF MODE (1------> 0) AND MP1_POKE ------------------------------
ONE_TO_ZERO:
xorl %ebx,%ebx    # clear ebx
movw $0, 10(%ecx) # update STATUS to zero     UPDATES STATUS!
movw 6(%ecx), %bx  # move the OFF_LENGTH into bx
movw %bx, 8(%ecx)  # move OFF_LENGTH into countdown UPDATES THE COUNTDOWN
xorl %ebx,%ebx # clear ebx again
movw (%ecx), %bx  # put location offset into bx
movl %ebx, %eax  # set the offset parameter for mp1_poke
movb 3(%ecx), %dl  # put off char into dl
xorl %ecx,%ecx  # clears ecx :( 
movb %dl, %cl # move the on char into cl for mp1_poke
call mp1_poke
jmp RET_FROM_SWITCH


jump_table:
.long mp1_ioctl_add, mp1_ioctl_remove,mp1_ioctl_find,mp1_ioctl_sync


mp1_ioctl:   # ECX USED
movl 8(%esp), %ecx # put the cmd parameter into ecx
cmp %ecx, $4 #check if cmd paramater is no more than 3
jle invalid # if it is invalid, go to invalid state
cmp %ecx,$0 # check if cmd parameter is less than 0 (invalid)
jg invalid # if it is below 0, go to invalid state
jmp *jump_table(,%ecx,4) # jump to coresponding address on jump table
ret

invalid1: movl $-1, %eax #if its invalid, return -1
ret
	

mp1_ioctl_add:    			#USES EDX(for pointer to struct user),EBX(for pointer to alloced), EAX


#----------------------------ALLOCATES STRUCT SPACE----------------------------------
movl 4(%esp),%edx		 #put the arg parameter into edx register, which is the user space struct address
cmp $0, %edx #NEWis the user space struct pointer pointing to something?
je badpointer    # NEW if not, that creates an error which is handled in badpointer
pushl %edx#NEW SAVE caller saved regs
pushl $16					 # push 16 bytes as the parameter for the size of the struct in bytes
call mp1_malloc 			#allocate the space
addl $4,%esp #NEWpop the argument
popl %edx#NEW put back caller saved reg
cmp $0,%eax						 #check if the pointer returned is null
je badpointer					 #if it is null, ERROR  jump to subroutine to take care of that\
movl %eax,%ebx			 #put the returned  pointer into ebx for use...
pushl $16 					# push first parameter which is the bytes copied
pushl %edx 						# push the "from" argument
pushl %ebx 						# push the "to" address as argument
call mp1_copy_from_user			# copy from user space to kernel space
popl %ebx#NEW pop the to address
popl %edx#NEW pop the from address
addl $4,%esp#NEW pop the argument
cmp $0,%eax						# did it return anything other than 0?
jne BADCOPY						# if so, this was a bad copy.. take care of the error 
xorl %eax, %eax#NEW clear out eax eax=0
addw $80, %ax#NEW 0+80-> ax
imulw $25,%ax,%ax  #NEW 80*25-> ax
addw $-1,%eax #NEW 80*25-1 -> ax
movw (%ebx), %cx #NEWpush location value (2 bytes) into cx
cmp $0, %cx #NEW2-1, aka how does 2 perform?
jb BADCOPY# NEWif location is less than 0, thats a bad location 
cmp %ax, %cx #NEW checks if location is above 80*25-1
ja BADCOPY#NEW if it is above that, undo that whole copy and allocation

#--------------------------------SETS UP STRUCT VALUES----------------------------------------------
# at this point, use ebx as the allocated pointer address in kernel space
xorl %ecx,%ecx # clear ecx 
movw 4(%ebx),%cx # get on_length field with 4 byte offset from beginning of struct
movw %cx, 8(%ebx) # set the countdown field (offset of 8) to value of on-length field (stored in cx)
movw $1, 10(%ebx) # set status field to 1
xorl %ecx,%ecx #clear ecx again
#---------------------------------CHANGE POINTER HEAD (INSERT INTO LIST)-----------------------------
# mp1_list_head has the long pointer (currently set to zero) and ebx has pointer to struct
movl mp1_list_head, %ecx #put the pointer of the list into ecx
movl %ecx, 12(%ebx) # make the next field point to the head of the list
movl %ebx, mp1_list_head # make mp1_list_head now point to the struct (add at the front)
xorl %ecx,%ecx # clear ecx again
#--------------------------------DISPLAY CHARACTER WITH MP1_POKE-------------------------------------
# edx gets clobbered for mp1_poke, low byte of char has ASCII value, high byte has color info
# eax offset, %cl has ascii code
movw (ebx), %cx #put linear offset location into cx
movl %ecx, %eax # put that linear offset into eax to use with mp1_poke
xorl %ecx,%ecx # clear ecx again
movb 2(ebx), %cl # push the ASCII character into %cl parameter
pushl %edx #save edx since it gets clobbered
call mp1_poke #display character on the screen
popl %edx # pop out edx if it got clobbered
pushl $0, %eax # at this point, it seems everything has gone well, so return 0
ret
#---------------------------ERROR HANDLING FOR ADD() FUNCTION--------------------------------
badpointer: 
pushl $-1, %eax 			# if a null pointer was returned at malloc, return -1
ret 

BADCOPY:
pushl %ebx					 # push the malloced memory into parameter
call mp1_free 				# free that memory 
popl %ebx#NEW pop out the parameter
pushl $-1,%eax 					# return -1 since there was an error
ret




