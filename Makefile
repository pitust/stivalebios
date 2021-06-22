D_SRCS = $(shell find src -type f | grep -v '\.[sc]$$')
D_SRCS_TRAMPOLINE_ONLY = $(shell find src/stivalebios/trampoline -type f | grep -v '\.[sc]$$')
D_SRCS_COMMON = $(shell find src/stivalebios/common -type f | grep -v '\.[sc]$$')
D_SRCS_FULL = $(shell find src -type f | grep -v '\.[sc]$$')

run: bin/bios_stage0.bin bin/bios_stage3.bin
	/usr/local/bin/qemu-system-x86_64 -bios bin/bios_stage0.bin \
		-d int -debugcon file:/dev/stdout -monitor stdio -no-shutdown -no-reboot \
		-fw_cfg name=opt/dev.pitust.stivalebios.config,file=config.ini \
		-fw_cfg name=opt/dev.pitust.stivalebios.fullbin,file=bin/bios_stage3.bin -M q35

bin/bios_stage0.bin: bios_stage0.s bin/bios_stage1.bin
	@echo AS $@
	@nasm -fbin bios_stage0.s -o bin/bios_stage0.bin

bin/bios_stage1.bin: bios_stage1.s bin/bios_stage2.bin
	@echo AS $@
	@nasm -fbin bios_stage1.s -o bin/bios_stage1.bin

bin/.objects_trampoline: $(D_SRCS_TRAMPOLINE_ONLY) $(D_SRCS_COMMON)
	@echo LDC2 'build/stivalebios.{common,trampoline}.*.o'
	@mkdir -p build/trampoline
	@ldc2 --float-abi=soft -code-model=kernel -mtriple x86_64-elf \
		-O0 --frame-pointer=all -betterC -c $(D_SRCS_TRAMPOLINE_ONLY) $(D_SRCS_COMMON) -od=build/trampoline -oq \
		-g --d-debug -mattr=-sse,-sse2,-sse3,-ssse3 --disable-red-zone
	@touch bin/.objects_trampoline

bin/.objects_full: $(D_SRCS_FULL) $(D_SRCS_COMMON) $(D_SRCS_FULL)
	@echo LDC2 'build/stivalebios.*.o'
	@mkdir -p build/full
	ldc2 --float-abi=soft -code-model=kernel -mtriple x86_64-elf \
		-O0 --frame-pointer=all -betterC -c $(D_SRCS_FULL) -od=build/full -oq \
		-g --d-debug -mattr=-sse,-sse2,-sse3,-ssse3 --disable-red-zone
	@touch bin/.objects_full

bin/bios_stage2.bin: bin/bios_stage2.elf
	objcopy -O binary bin/bios_stage2.elf bin/bios_stage2.bin

bin/bios_stage3.bin: bin/bios_stage3.elf
	objcopy -O binary bin/bios_stage3.elf bin/bios_stage3.bin

bin/bios_stage2.elf: bios_stage2.s trampoline.ld bin/.objects_trampoline
	@echo AS bin/bios_stage2_ldr.o
	@nasm -felf64 bios_stage2.s -o bin/bios_stage2_ldr.o
	@mkdir -p build
	@ld.lld -T trampoline.ld bin/bios_stage2_ldr.o `echo build/trampoline/*` -o bin/bios_stage2.elf

bin/bios_stage3.elf: bios_stage3.s stage3.ld bin/.objects_full
	@echo AS bin/bios_stage3_ldr.o
	@nasm -felf64 bios_stage3.s -o bin/bios_stage3_ldr.o
	@mkdir -p build
	@ld.lld -T stage3.ld bin/bios_stage3_ldr.o `echo build/full/*` -o bin/bios_stage3.elf