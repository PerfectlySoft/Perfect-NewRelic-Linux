tar czvf /tmp/nr.tgz Sources Tests Package.swift
scp /tmp/nr.tgz apa:/tmp/nr.tgz
ssh apa "cd /tmp; rm -rf nr; mkdir nr; cd nr;tar xzvf /tmp/nr.tgz; swift test"
