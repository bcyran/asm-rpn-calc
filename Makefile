AS			= gcc
ASFLAGS		= -g

TARGET		= asm-rpn-calc

SOURCES		= $(wildcard src/*.s)

$(TARGET) : $(SOURCES)
	$(AS) $(ASFLAGS) -o $(TARGET) $(SOURCES)
					
