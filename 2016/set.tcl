

##################################
#     Set Up Design Compiler     #
##################################
source synopsys_dc.setup

#######################
#     Read Design     #
#######################
read_file LBP.v

#######################
# source sdc 
#######################
source LBP.sdc

###################
#     Compile     #
###################
compile


#########################
#     Output            #
#########################
write -format verilog -hierarchy -output LBP_syn.v
write -format ddc -hierarchy -output LBP_syn.ddc
write_sdf -version 2.1 LBP_syn.sdf
