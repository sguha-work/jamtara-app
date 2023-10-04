.PHONY: build clean deploy gomodgen

build: gomodgen
	export GO111MODULE=on
	env GOOS=linux go build -ldflags="-s -w" -o bin/consumers consumers/main.go
	env GOOS=linux go build -ldflags="-s -w" -o bin/world world/main.go
	env GOOS=linux go build -ldflags="-s -w" -o bin/agentRegion circle/main.go
	env GOOS=linux go build -ldflags="-s -w" -o bin/fetchDivisionDetails circle/fetchDivisionDetails.go
	env GOOS=linux go build -ldflags="-s -w" -o bin/fetchAllDivision circle/fetchAllDivision.go




clean:
	rm -rf ./bin ./vendor go.sum

deploy: clean build
	sls deploy --verbose

gomodgen:
	chmod u+x gomod.sh
	./gomod.sh
