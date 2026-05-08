opcodes = {
   "ADD": "000",
   "ADDI": "001",
   "LOAD": "010",
   "STORE": "011",
   "BLT": "100",
   "NAND": "101",
   "SHFT": "110",
   "SHFTI": "111",
}


registers = {
   "r0": "000",
   "r1": "001",
   "r2": "010",
   "r3": "011",
   "r4": "100",
   "r5": "101",
   "r6": "110",
   "r7": "111"
}


directions = {
   "L": "0",
   "R": "1"
}


def clean_and_tokenize(line):
   # 1. get everything before the comment
   code_portion = line.split("//")[0]


   # 2. replace commas with white space
   clean_line = code_portion.replace(",", " ")


   # 3. split into list of words
   tokens = clean_line.split();


   return tokens


def process_file(file):
   instructions = []  # Our 2D array (list of lists)
   labels = {}        # Our map for bookmarks
   current_instruction = 0
  
   for line in file:
       tokens = clean_and_tokenize(line)
      
       # Skip empty lines (like lines that were just comments)
       if not tokens:
           continue
          
       # Check: Is this a label or an instruction?
       if tokens[0].endswith(":"):
           # It's a label! (e.g., "loop:")
           label_name = tokens[0].replace(":", "")
           # Save the current position (how many instructions we've found so far)
           labels[label_name] = current_instruction
       else:
           # It's a real instruction!
           if (tokens[0] == "BLT" and tokens[1] not in registers):
               instructions.append(["ADDI_PLACEHOLDER"])
               instructions.append(tokens)
               current_instruction += 2
           else:
               instructions.append(tokens)
               current_instruction += 1
          
   return instructions, labels


def process_tokens(tokens):
   opcode_bits = opcodes[tokens[0]]


   if (tokens[0] == "ADD" or tokens[0] == "NAND"):
       rd = registers[tokens[1]]
       r1 = registers[tokens[2]]
       r2 = registers[tokens[3]]
       empty_bits = "0000"
       return opcode_bits + rd + r1 + r2 + empty_bits
  
   elif (tokens[0] == "ADDI"):
       rd = registers[tokens[1]]
       r1 = registers[tokens[2]]
       imm = int(tokens[3].replace("#", ""))
       imm_bits = format(imm & 0x3F, '06b')
       empty_bits = "0"
       return opcode_bits + rd + r1 + imm_bits + empty_bits


   elif (tokens[0] == "LOAD"):
       ra = registers[tokens[1]] # take value from (RAM)
       rv = registers[tokens[2]] # load value into (CPU)
       empty_bits = "0000000"
       return opcode_bits + ra + rv + empty_bits
  
   elif (tokens[0] == "STORE"):
       ra = registers[tokens[2]] # load value into (RAM)
       rv = registers[tokens[1]] # take value from (CPU)
       empty_bits = "0000000"
       return opcode_bits + ra + rv + empty_bits
  
   elif (tokens[0] == "BLT"):
       ro = registers[tokens[1]]
       r1 = registers[tokens[2]]
       r2 = registers[tokens[3]]
       empty_bits = "0000"
       return opcode_bits + ro + r1 + r2 + empty_bits
  
   elif (tokens[0] == "SHFT"):
       rd = registers[tokens[1]]
       r1 = registers[tokens[2]]
       r2 = registers[tokens[3]]
       empty_bits = "000"
       lr_bit = directions[tokens[4]]
       return opcode_bits + rd + r1 + r2 + empty_bits + lr_bit


   elif (tokens[0] == "SHFTI"):
       rd = registers[tokens[1]]
       r1 = registers[tokens[2]]
       imm = int(tokens[3].replace("#", ""))
       imm_bits = format(imm & 0x3F, '06b')
       lr_bit = directions[tokens[4]]
       return opcode_bits + rd + r1 + imm_bits + lr_bit
      
def assemble(file_path):
   # Open the file and run Pass 1
   with open(file_path, 'r') as f:
       instructions, labels = process_file(f)
  
   machine_code = []


   # Pass 2: Translate each instruction
   i = 0
   while i < len(instructions):
       if instructions[i][0] == "ADDI_PLACEHOLDER":
           # 1. Handle the ADDI part using instructions[i]
           label_name = instructions[i + 1][1]
           target_address = labels[label_name]
           current_address = i
           offset = target_address - current_address - 1
           offset_string = '#' + str(offset)


           addi_instructions = ['ADDI', 'r4', 'r0', offset_string]
           binary_str_1 = process_tokens(addi_instructions)
           machine_code.append(binary_str_1)


           # 2. Handle the BLT part using instructions[i + 1]
           blt_instructions = [instructions[i+1][0], 'r4', instructions[i+1][2], instructions[i+1][3]]
           binary_str_2 = process_tokens(blt_instructions)
           machine_code.append(binary_str_2)
          
           i += 2
       else:
           # Handle a normal single instruction
           binary_str = process_tokens(instructions[i])
           machine_code.append(binary_str)
           i += 1
  
   return machine_code


with open("program.hex", "w") as f:
   machine_code = assemble("fibonacci.asm")
   for code in machine_code:
       f.write(code + "\n")

