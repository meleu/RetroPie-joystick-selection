# RetroPie-joystick-selection <img src="./icon.png" width="48" align="right" />

A script to let the user choose the controllers to use for RetroArch players 1-4. It shows several user-friendly dialog boxes to perform this task. You can set the global and/or the system specific configuration.

The joystick selection has two methods of work:

1. The traditional joystick selection by its index number
2. The **joystick selection by name method** [recommended]

The advantage of the selection by name method is that there is no need to care about the joystick connection order. You can configure your "Generic USB SNES gamepad" to be the player1 no matter what USB port you use. Or, better yet, configure your "Fancy Bluetooth joypad" to be the player1 no matter what was the order it was paired or how many USB joysticks are connected.

It was made for use with [RetroPie](https://retropie.org.uk/) only.

## Installation

1. If you're on EmulationStation, press `F4` to go to the Command Line Interface.

2. Download the `install.sh` script, and launch it:

```bash
wget -O- "https://raw.githubusercontent.com/meleu/RetroPie-joystick-selection/master/install.sh" | sudo bash
```

3. **After that you are ready to use it via RetroPie menu in emulationstation:**

```bash
emulationstation
```


## Update

After installing, you can update it through RetroPie-Setup.

To update the joystick-selection tool, go to RetroPie-Setup and:

*Manage packages* >> *Manage experimental packages* >> *joystick-selection* >> *Update from source*


## Donate

If you would like to buy me a beer and say thanks, click the button below.

[![paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donate_SM.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=ZZ3ZN4T7D65EY)

## Screenshots

**Main menu:**

![main-meu](https://cloud.githubusercontent.com/assets/8508804/17637919/35b71b06-60bd-11e6-91ba-c598aaee806c.png)


**Global configuration (with no configs):**

![config-all-unset](https://cloud.githubusercontent.com/assets/8508804/17637916/35b1c9e4-60bd-11e6-8c58-456c59bbfed0.png)


**Joystick selection screen:**

![joy-select](https://cloud.githubusercontent.com/assets/8508804/17638622/b1f454c8-60c1-11e6-9e10-0fc9debaadcd.png)


**Global configuration (by index method, all 4 joysticks are set):**

![config-all-index](https://cloud.githubusercontent.com/assets/8508804/17637918/35b2e392-60bd-11e6-996b-2a4db69be500.png)


**Global configuration (by name method, all 4 joysticks are set):**

![config-all-configured](https://cloud.githubusercontent.com/assets/8508804/17637912/2d349e72-60bd-11e6-80e5-38460a0b2dd7.png)


**Systems menu (I have just a few of them installed):**

![system-menu](https://cloud.githubusercontent.com/assets/8508804/17637920/35bb4334-60bd-11e6-8926-669ad5b08fa8.png)


**System specific (by index method, some joysticks are set):**

![config-nes-index](https://cloud.githubusercontent.com/assets/8508804/17637921/35bbca48-60bd-11e6-849a-39e835937c24.png)


**System specific (by name method, some joysticks are set):**

![config-nes](https://cloud.githubusercontent.com/assets/8508804/17637917/35b258aa-60bd-11e6-9e01-c64876afb20d.png)



## Limitation

- If you are using joysticks with equal names, then, yes, the connection order matters.
