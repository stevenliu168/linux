cc=g++
dst=hel.out
header=$(shell find ./ -iname "*.h" )
src=$(shell find ./ -iname "*.cpp" )
objs=$(src:%.cpp=%.o)


$(dst) : $(objs)
	$(cc) -o $(dst)  $(objs)

%.o: %.cpp  $(header)
	$(cc) -c $< -o $@   #其中 $<表示冒号后的依赖文件 *.cpp  $@代表生成的冒号前面的 *.o

clean:
	rm -f *.o  *.exe  *~  *.out
