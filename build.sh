#!/bin/bash

NAME="my_printf"
RESET="\e[m"
RED="\e[1;31m"
GREEN="\e[1;32m"
YELLOW="\e[1;33m"

echo -e "\nOptions:"
echo "-  build -  Build"
echo "-  list  -  Open listing file"
echo "-  link  -  Link"
echo "-  comp  -  Build and link"
echo "-  run   -  Run without compile"
echo "-  crun  -  Compile and run"
echo "-  name  -  Change name"
echo "-  debug -  Open with gdb"
echo "-  end   -  Exit"
echo

if [[ $# -gt 0 ]]; then
	NAME="$1"
fi

echo -e "Current name: ${YELLOW}${NAME}${RESET}"
echo

cd /mnt/c/Users/user/Documents/Assem
( [ -d ${NAME} ] || mkdir ${NAME} ) && cd ${NAME}

while true; do
	read -p "> " choice

	case $choice in

		build)
			echo -e "${YELLOW} Start building \"${NAME}.asm\"... ${RESET}"
			nasm -f elf64 ${NAME}.asm -l ${NAME}.lst -g -F dwarf -o ${NAME}.o
			if [[ $? -eq 0 ]]; then
				echo -e "${GREEN} Builded successfully, \"${NAME}.o\" and \"${NAME}.lst\" saved ${RESET}"
			else
				error=$?
				echo -e "${RED} Building failed, exit code: ${error} ${RESET}"
			fi
			;;

		link)
			echo -e "${YELLOW} Start linking \"${NAME}.o\"...${RESET}"
			gcc -no-pie -Wl,--no-warn-execstack ${NAME}.o ../test.c -o ${NAME} -g
			if [[ $? -eq 0 ]]; then
				echo -e "${GREEN} Linked successfully, file \"${NAME}\" saved ${RESET}"
			else
				error=$?
				echo -e "${RED} Linking failed, exit code: ${error} ${RESET}"
			fi
			;;

		list)
			nano ${NAME}.lst
			;;

		comp)
			echo -e "${YELLOW} Start compiling \"${NAME}.asm\"... ${RESET}"
			nasm -f elf64 ${NAME}.asm -g -F dwarf -l ${NAME}.lst -o ${NAME}.o && gcc -no-pie -Wl,--no-warn-execstack ${NAME}.o ../test.c -o ${NAME} -g
			if [[ $? -eq 0 ]]; then
				echo -e "${GREEN} Compilated successfully, file \"${NAME}\" saved ${RESET}"
			else
				error=$?
				echo -e "${RED} Compilation failed, exit code: ${error} ${RESET}"
			fi
			;;

		run)
			echo -e "${YELLOW} Runnning \"${NAME}\"... ${RESET}"
			./${NAME}
			if [[ $? -eq 0 ]]; then
				echo -e "${GREEN} Successfully ${RESET}"
			else
				echo -e "${RED} Failed ${RESET}"
			fi
			;;

		crun)

			echo -e "${YELLOW} Start compiling \"${NAME}.asm\"...${RESET}"
			nasm -f elf64 ${NAME}.asm -g -F dwarf -l ${NAME}.lst -o ${NAME}.o
			if [[ $? -eq 0 ]]; then
				echo -e "${GREEN} Successfully builded, file \"${NAME}.o\" and \"${NAME}.lst\" saved... ${RESET}"
			else
				error=$?
				echo -e "${RED} Building failed, exit code: ${error} ${RESET}"
				continue
			fi

			gcc -no-pie -Wl,--no-warn-execstack ${NAME}.o ../test.c -o ${NAME} -g
			if [[ $? -eq 0 ]]; then
				echo -e "${GREEN} Successfully linked, file \"${NAME}\" saved... ${RESET}"
			else
				error=$?
				echo -e "${RED} Linking faildd, exit code: ${error} ${RESET}"
				continue
			fi

			echo -e "${GREEN} Successfully compilied... ${RESET}"
			echo -e "${YELLOW} Running \"${NAME}\"... ${RESET}"
			./${NAME}

			if [[ $? -eq 0 ]]; then
				echo -e "${GREEN} Successfully !!! ${RESET}"
			else
				error=$?
				echo -e "${RED} Running failed, exit code: ${error} ${RESET}"
			fi

			;;

		name)
			cd ..
			echo -e " Current name: ${YELLOW}${NAME}${RESET}"
			echo -n -e "Enter new name: ${YELLOW}"
			read line
			echo -n -e "${RESET}"
			NAME="$line"
			echo -e "${GREEN} Current name: ${YELLOW}${NAME}${RESET}"
			( [ -d ${NAME} ] || mkdir ${NAME} ) && cd ${NAME}
			;;

		debug)
			gdb ./${NAME}
			;;

		end)
			echo -e "${GREEN} Goodbye :) ${RESET}\n"
			exit 0
			;;

		*)
			eval $choice
			;;

	esac

done
