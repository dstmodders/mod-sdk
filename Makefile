GIT_LATEST_TAG = $$(git describe --abbrev=0)

# Source: https://stackoverflow.com/a/10858332
__check_defined = $(if $(value $1),, $(error Undefined $1$(if $2, ($2))))
check_defined = $(strip $(foreach 1,$1, $(call __check_defined,$1,$(strip $(value 2)))))

help:
	@printf "Please use 'make <target>' where '<target>' is one of:\n\n"
	@echo "   dev                   to run ldoc + lint + testclean + test"
	@echo "   ldoc                  to generate an LDoc documentation"
	@echo "   lint                  to run code linting"
	@echo "   luacheckglobals       to print Luacheck globals (mutating/setting)"
	@echo "   luacheckreadglobals   to print Luacheck read_globals (reading)"
	@echo "   release               to update version"
	@echo "   test                  to run Busted tests"
	@echo "   testclean             to clean up after tests"
	@echo "   testcoverage          to print the tests coverage report"
	@echo "   testlist              to list all existing tests"

dev: ldoc lint testclean test

ldoc:
	@find ./docs/* -type f -not -name Dockerfile -not -name docker-stack.yml -not -wholename ./docs/ldoc/ldoc.css -delete
	@ldoc .

lint:
	@EXIT=0; \
		printf "Luacheck:\n\n"; luacheck . --exclude-files="here/" || EXIT=$$?; \
		printf "\nPrettier:\n\n"; prettier --check \
			'./**/*.md' \
			'./**/*.xml' \
			'./**/*.yml' \
		|| EXIT=$$?; \
		exit $${EXIT}

luacheckglobals:
	@luacheck . --formatter=plain | grep 'non-standard' | awk '{ print $$6 }' | sed -e "s/^'//" -e "s/'$$//" | sort -u

luacheckreadglobals:
	@luacheck . --formatter=plain | grep "undefined variable" | awk '{ print $$5 }' | sed -e "s/^'//" -e "s/'$$//" | sort -u

test:
	@busted .; luacov -r lcov > /dev/null 2>&1 && cp luacov.report.out lcov.info; luacov-console . && luacov-console -s

testclean:
	@rm -f busted.out core lcov.info luacov*

testcoverage:
	@luacov -r lcov > /dev/null 2>&1 && cp luacov.report.out lcov.info; luacov-console . && luacov-console -s

testlist:
	@busted --list . | awk '{$$1=""}1' | awk '{gsub(/^[ \t]+|[ \t]+$$/,"");print}'
