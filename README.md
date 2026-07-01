# CPEE Light

Switch off secureboot.

```bash
  git clone https://github.com/frank-zago/ch341-i2c-spi-gpio
  cd ch341-i2c-spi-gpio
  make
  sudo make install
```

Reboot. Jumper to I2C/GPIO. Plugin in. 

Try everything below as root:

```bash
  gpioinfo
```

It should be the last in the list.

```bash
  gpioset -c gpiochip1 -t0 0=0
  gpioset -c gpiochip1 -t0 0=1
```

Now init i2c or use "cpee-light init":

```bash
  i2cdetect -l
  i2cdetect -y 20 # if 20 is your CH341
  echo bh1750 0x23 | tee /sys/bus/i2c/devices/i2c-20/new_device # if 20 is your CH341
  cd /sys/bus/iio/devices/iio:device0
  cat in_illuminance_raw
```

Play with integration time for sampling rate (0.12s default, 0.2s when dark, 0.05s when bright). Some things have to be done as root.

Use the "cpee-light init" command for i2c init after compile. Add YOUR-USER to a group ch431 as proposed in frank zagos documentation to use service as user:

```bash
  groupadd ch341
  usermod -a -G ch341 YOUR-USER
  echo 'SUBSYSTEMS=="usb" ATTRS{idProduct}=="5512" ATTRS{idVendor}=="1a86" GROUP="ch341" MODE="0660"' > /etc/udev/rules.d/99-ch341.rules
```



