#

#

#

#

#

#

#

#

go get -u ./...

go run cmd/server/main.go

adb -s 5200d78bfa479449 reverse tcp:8080 tcp:8080
