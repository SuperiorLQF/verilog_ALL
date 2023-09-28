#axi_inout_generate.py
#dependency:
'''
Csv_File
Module_File
Output_File
'''
#function
'''
funct1:to generate axi input/output(wire) by specify prefix through a csv
funct2:to auto inst axi module
'''
##后续可以加入位宽匹配等
import csv
import os
import sys
Module_File_List=[]#The list that contains Module_Files  //TODO,现在只是一个ModuleFile

Infix='axi'

INDEX_NUM=4 #how many axi port we need
content=[]#content to be written in Output_File
header=['DIR','WIDTH','PREFIX','AXI_SIG/ONCE','TYPE','INDEX']#csv header

STD_DIR_INDEX=0
STD_TYPE_INDEX=1
STD_WIDTH_A_INDEX=2
STD_WIDTH_B_INDEX=3
STD_NAME_INDEX=4
'''
signal standard format (之后可以用嵌套的class实现对文件类)
[DIR,TYPE,WIDTH_A,WIDTH_B,NAME](之后可以加上SRC,DEST,LINENUM等做更加复杂的分析)
DIR:-1内部信号,0 input,1output,
TYPE: 0 wire 1 reg
举例
[0,'reg','7','3a+1',aaa]
'''

#judge the signal name_judge is axi master signal or slave signal 
def MSjudge(name_judge):
    if(('m' in name_judge )or('M' in name_judge)or('MST' in name_judge)or('mst' in name_judge)):
        return 1
    elif(('s' in name_judge )or('S' in name_judge)or('SLV' in name_judge)or('slv' in name_judge)):
        return -1
    else: 
        return 0
#convert inout csv into signal std format
def cvt2sig_std(line_dict,INDEX_NUM):
    sig_std=[]
    sig_dir=0 if line_dict['DIR']=='0' else 1
    width_split=line_dict['WIDTH'].split()
    width_split=[] if width_split ==[] else width_split[0][1:-1]
    width_split=[] if width_split ==[] else width_split.split(':')
    sig_width_a,sig_width_b=width_split if width_split != [] else ['0','0']
    if(line_dict['AXI_SIG/ONCE']=='1'):##下面这两种是inout_user_csv_file格式
        sig_name=(line_dict['PREFIX']).ljust(25)
    elif(line_dict['AXI_SIG/ONCE']=='0'):
        sig_name=(line_dict['PREFIX']+'_'+line_dict['INDEX']).ljust(25)  
    else:
        sig_name=(line_dict['PREFIX']+'_'+line_dict['INDEX']+'_'+Infix+'_'+line_dict['AXI_SIG/ONCE']).ljust(25) if INDEX_NUM>1 else  (line_dict['PREFIX']+Infix+'_'+line_dict['AXI_SIG/ONCE']).ljust(25) 


    sig_type=0 if line_dict['TYPE']=='0' else 1
    sig_std=[sig_dir,sig_type,sig_width_a,sig_width_b,sig_name]
    return sig_std

#in:csv out:std_list
def get_inout_sig_std_list(CsvFilename=None,INDEX_NUM=1):
    if(CsvFilename==None):
        print('\033[44m[hint]\033[0m:\tYou do not specify \033[4m IO CSV File.\033[0m')
        return []
    with open(CsvFilename,'r') as file:   
        reader = csv.reader(file)
        j=0
        for row in reader:
            j=j+1
        if(j<=1):
            print('\033[44m[hint]\033[0m:\tYour IO CSV File \033[4m{}\033[0m seems to be empty.'.format(CsvFilename))
            return []
    inout_sig_std_list=[]
    for index in range(INDEX_NUM):
        ONCE_sig_std_list=[]
        with open(CsvFilename,'r') as file:
            reader = csv.reader(file)
            i=0 #which line(line0 is header of csv)
            for row in reader:
                if(i>0):
                    a=str(index)
                    row.append(a)
                    line_dict=dict(zip(header,row))
                    if(line_dict['AXI_SIG/ONCE']=='1'):#单次出现
                        inout_sig_std=cvt2sig_std(line_dict,INDEX_NUM)
                        #单次出现检查
                        if(inout_sig_std not in ONCE_sig_std_list):
                            ONCE_sig_std_list.append(inout_sig_std)
                    else:
                        inout_sig_std=cvt2sig_std(line_dict,INDEX_NUM)#convert to standard signal format
                        inout_sig_std_list.append(inout_sig_std)
                i=i+1
    inout_sig_std_list=ONCE_sig_std_list+inout_sig_std_list
    return inout_sig_std_list
def get_parameter_list(CsvFilename=None):
    if(CsvFilename==None):
        print('\033[44m[hint]\033[0m:\tYou do not specify \033[4m Parameter CSV File.\033[0m')
        return []        
    parameter_list=[]
    with open(CsvFilename,'r') as file:
        reader = csv.reader(file) 
        j=0
        for row in reader:
            j=j+1
        if(j<=1):
            print('\033[44m[hint]\033[0m:\tYour Parameter CSV File \033[4m{}\033[0m seems to be empty.'.format(CsvFilename))
            return []
    with open(CsvFilename,'r') as file:
        reader = csv.reader(file)
        i=0
        for row in reader:
            row_split=[]
            if(i>0):
                for item in row:
                    if(type(item)==type('aaa')):#if item is a str,split it to remove space     
                        row_split.append(item.split()[0])
                    else:
                        row_split.append(item)
                parameter_list.append(row_split)
            i=i+1
    return parameter_list        
#inout_std -> inout content
def inout_print_formatter(std_list,parameter_list,module_name='default_module'):
    if(module_name=='default_module'):
        print('\033[44m[hint]\033[0m:\tYou do not specify \033[4m module name\033[0m, use default module name.')
    inout_content=[]
    '''add module name to content'''
    inout_content.append('module {} #(\n'.format(module_name))

    '''add parameter to content'''
    for item in parameter_list:
        parameter_value_str=str(item[-1])
        inout_content.append(('\t'+item[0].ljust(15)+item[1].ljust(30)+' = '+parameter_value_str.ljust(5)+',\n'.rjust(5)) if (item!=parameter_list[-1] ) else ('\t'+item[0].ljust(10)+item[1].ljust(30)+' = '+parameter_value_str.ljust(5)+'\n'.rjust(5)))
    inout_content.append(')(\n')
    
    '''add inout to content'''
    for std_signal in std_list:
        line=['','','','',',\n'] if (std_signal!=std_list[-1]) else ['','','','','\n']
        line[0]='input'.ljust(8) if std_signal[0]==0 else 'output'.ljust(8)
        line[1]=''.ljust(5) if std_signal[1]==0 else 'reg'.ljust(5)
        line[2]=('['+std_signal[2]+':'+std_signal[3]+']').ljust(25) if std_signal[2]!=std_signal[3] else ''.ljust(25)
        line[3]=std_signal[4]
        line_str=line[0]+line[1]+line[2]+line[3]+line[4]
        inout_content.append(line_str)
    inout_content.append(');\n')
    
    return inout_content

def inst_module(module_name,io_std_lst,inst_NUM):#read from a .sv file
    port_fail_num=0
    inst_content=[]
    for index in range(inst_NUM):
        port_dict=dict()#需要例化的模块的端口信息,{<name:dir>},dir=0为input
        with open(module_name,'r',encoding='utf-8') as f:
            content_m=f.readlines()
            for line in content_m:
                if('input' in line ):
                    port_dict[(line.split()[-1])[:-1]]=0#get the dir &port name
                elif('output' in line):
                    port_dict[(line.split()[-1])[:-1]]=1#get the dir &port name
        port_list_keys=list(port_dict.keys())
        inst_content.append('u_{}_{}(\n'.format(module_name.split('.')[0],index))####inst_name
        for item in port_list_keys:#item为实例化的端口名字
            tmp_list=[]
            for one_signal in io_std_lst:
                pure_signal_name=one_signal[STD_NAME_INDEX].split('_')[-1]
                pure_signal_name=pure_signal_name.split()[-1]
                if (pure_signal_name in item):#正筛：内部信号包含外部信号
                    
                    module_port_frag=item.split('_')
                    for port in module_port_frag:#反筛：外部信号包含内部信号
                        if(port==pure_signal_name):
                            tmp_list.append(one_signal)#加入列表中
            
            if(tmp_list==[]):#该信号不是AXI信号
                port_fail_num=port_fail_num+1
                item1='\t.'+(item).ljust(20)+'(!!!)\n'  if(item==port_list_keys[-1]) else '\t.'+(item).ljust(20)+'(!!!),\n'
            else:#该信号是AXI信号，现在进行匹配mst，slv,index,dir,#暂时还没有加位宽匹配,位宽匹配需要结合参数
                ####匹配逻辑
                match_std_signal=[]
                for candidate_std_sig in tmp_list:
                    index_str=str(index)
                    sig_index=candidate_std_sig[STD_NAME_INDEX].split('_')[1]
                    sig_prefix=candidate_std_sig[STD_NAME_INDEX].split('_')[0]
                    if((sig_index==index_str) and (MSjudge(sig_prefix)==MSjudge(item))):                            
                        if(candidate_std_sig[STD_DIR_INDEX]==port_dict[item]):
                            match_std_signal=candidate_std_sig                                
                        else:
                            print('\033[43m[Warning]\tdirection not match\033[0m')
                            output_info='\033[33mINPUT \t{}\033[0m'.format(candidate_std_sig[STD_NAME_INDEX]) if candidate_std_sig[STD_DIR_INDEX]==0 else '\033[33mOUTPUT\t{}\033[0m'.format(candidate_std_sig[STD_NAME_INDEX])
                            print('extern_port:\t'+output_info)
                            output_info='\033[33mINPUT \t{}\033[0m'.format(item) if port_dict[item]==0 else '\033[33mOUTPUT\t{}\033[0m'.format(item)
                            print('module_port:\t'+output_info+'\tin \"{}\"'.format(INST_Module_File))
                            print('--------------------------------------------------')
                if(match_std_signal==[]):
                    port_fail_num=port_fail_num+1
                    item1='\t.'+(item).ljust(20)+'(!!!)\n'  if(item==port_list_keys[-1]) else  '\t.'+(item).ljust(20)+'(!!!),\n'   
                else:     
                    item1='\t.'+(item).ljust(20)+'('+match_std_signal[STD_NAME_INDEX]+')\n' if(item==port_list_keys[-1]) else '\t.'+(item).ljust(20)+'('+match_std_signal[STD_NAME_INDEX]+'),\n'
            inst_content.append(item1)
        inst_content.append(');\n')
    print('\033[44m[hint]\033[0m:\t\033[4m{} port(s)\033[0m fail to map in total.'.format(port_fail_num))
    return inst_content

def io_generate(module_name='default_module',INDEX_NUM=1,Inout_fixed_csv_File=None,Inout_user_csv_File=None,parameter_csv_File=None):
    parameter_list=get_parameter_list(parameter_csv_File)
    io_fixed_std_lst=get_inout_sig_std_list(Inout_fixed_csv_File,INDEX_NUM)
    io_user_std_lst=get_inout_sig_std_list(Inout_user_csv_File,INDEX_NUM)
    inout_content=inout_print_formatter(io_user_std_lst+io_fixed_std_lst,parameter_list,module_name)#默认user_signal在前，也可以指定
    print('\033[42m[info]:\033[0m\t\033[32mIO Generate Done!\033[0m')#Print Green info    
    return inout_content
'''main'''
if __name__== '__main__':
    '''specify the files'''
    Generate_module_name=os.environ['Generate_module_name']
    Generate_INDEX_NUM=os.environ['Generate_INDEX_NUM']
    Generate_Output_File=os.environ['Generate_Output_File']#'test1.sv'
    Inout_fixed_csv_File=os.environ['Inout_fixed_csv_File']#'axi_inout_generate.csv'#generate inout based on this file
    Inout_user_csv_File=os.environ['Inout_user_csv_File']#  'inout_generate.csv'
    parameter_csv_File=os.environ['parameter_csv_File']#    'axi_parameter.csv'

    INST_Module_File=os.environ['INST_Module_File']#        "axi_reg_slice_ft.sv"

    aaa=io_generate(
                module_name=Generate_module_name,\
                INDEX_NUM=Generate_INDEX_NUM,\
                Inout_fixed_csv_File='axi_inout_generate.csv',\
                Inout_user_csv_File='inout_generate.csv',\
                parameter_csv_File='axi_parameter.csv')
    with open(Generate_Output_File,'r+',encoding='utf-8') as f:
        f.writelines(aaa)
        f.writelines(['endmodule\n'])
    print('\033[42m[info]:\033[0m\t\033[32mWritten in file Done!\033[0m')#Print Green info

    # parameter_list=get_parameter_list(parameter_csv_File)
    # io_fixed_std_lst=get_inout_sig_std_list(Inout_fixed_csv_File)
    # io_user_std_lst=get_inout_sig_std_list(Inout_user_csv_File)
    # inout_content=inout_print_formatter(io_user_std_lst+io_fixed_std_lst,parameter_list)#默认user_signal在前，也可以指定
    
    # aaa=inst_module(Module_File,io_fixed_std_lst,4)
    # with open(Output_File,'r+',encoding='utf-8') as f:
    #     f.writelines(inout_content)
    #     f.writelines(aaa)
    #     f.writelines(['endmodule\n'])
    # print('\033[32mDone!\033[0m')#Print Green info

