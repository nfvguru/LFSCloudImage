#!/bin/sh

cat > $LFS/makeimage.sh << "EOF"
#!/bin/sh
cp -dpf /sources/cloudinstall /bin
chmod +x /bin/cloudinstall
make image 2>&1 1>/dev/null
EOF

chmod +x $LFS/makeimage.sh

