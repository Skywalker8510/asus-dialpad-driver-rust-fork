#!/usr/bin/env bash

source non_sudo_check.sh

# i2cdetect is /usr/sbin/i2cdetect and some distributions do not add sbin to $PATH (https://github.com/asus-linux-drivers/asus-numberpad-driver/issues/154)
# https://github.com/asus-linux-drivers/asus-numberpad-driver/issues/218
if [[ $(type /usr/sbin/i2cdetect 2>/dev/null) ]] && [[ $(type /usr/sbin/i2ctransfer 2>/dev/null) ]]; then
    INTERFACES=$(for i in $(sudo /usr/sbin/i2cdetect -l | grep DesignWare | sed -r "s/^(i2c\-[0-9]+).*/\1/"); do echo $i; done)

    if [ -z "$INTERFACES" ]; then
        echo "No i2c interface can be found. Make sure you have installed libevdev packages"
        exit 1
    fi

    TOUCHPAD_WITH_DIALPAD_DETECTED=
    for INDEX in $INTERFACES; do
        echo -n "Testing interface $INDEX: "

        NUMBER=$(echo -n $INDEX | cut -d'-' -f2)
        DIALPAD_OFF_CMD="sudo /usr/sbin/i2ctransfer -f -y $NUMBER w13@0x15 0x05 0x00 0x3d 0x03 0x06 0x00 0x07 0x00 0x0d 0x14 0x03 0x00 0xad"
        I2C_TEST_15=$($DIALPAD_OFF_CMD 2>&1)

        # https://github.com/asus-linux-drivers/asus-numberpad-driver/issues/161
        DIALPAD_OFF_CMD="sudo /usr/sbin/i2ctransfer -f -y $NUMBER w13@0x38 0x05 0x00 0x3d 0x03 0x06 0x00 0x07 0x00 0x0d 0x14 0x03 0x00 0xad"
        I2C_TEST_38=$($DIALPAD_OFF_CMD 2>&1)

        if [ -z "$I2C_TEST_15" ]; then
            echo "success (adr 0x15)"
            TOUCHPAD_WITH_DIALPAD_DETECTED=true
            break
        elif [ -z "$I2C_TEST_38" ]; then
            echo "success (adr 0x38)"
            TOUCHPAD_WITH_DIALPAD_DETECTED=true
            break
        else
            echo "failed"
        fi
    done

    if [ -z "$TOUCHPAD_WITH_DIALPAD_DETECTED" ]; then
        echo "The detection was not successful. Touchpad with DialPad not found. Check whether your touchpad has integrated DialPad (e.g. on product websites) and then eventually create an issue here https://github.com/asus-linux-drivers/asus-dialpad-driver/issues/new/choose."
        exit 1
    fi
else
    echo "The i2cdetect or i2ctransfer tool not found to proceed initial test whether any i2c device react like DialPad"
fi