AS			= gcc
ASFLAGS		= -g

TARGET		= asm-rpn-calc

SOURCES		= src/main.s


$(TARGET) : $(SOURCES)
	$(AS) $(ASFLAGS) -o $(TARGET) $(SOURCES)
					
