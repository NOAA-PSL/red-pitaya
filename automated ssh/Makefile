CFLAGS  = -Wall -std=c++20 ## -Werror
CFLAGS += -I/opt/redpitaya/include
LDFLAGS = -L/opt/redpitaya/lib
LDLIBS = -static -lrp-hw-can -lrp -lrp-hw-calib -lrp-hw-profiles

LDLIBS += -lrp-gpio -lrp-i2c
LDLIBS += -lrp-hw -lm -lstdc++ -lpthread -li2c -lsocketcan

# List of programs to compile
PRGS := $(basename $(wildcard *.cpp))


all: $(PRGS)

%: %.cpp
	$(CXX) $< $(CFLAGS) $(LDFLAGS) $(LDLIBS) -o $@

clean:
	$(RM) $(PRGS) *.o