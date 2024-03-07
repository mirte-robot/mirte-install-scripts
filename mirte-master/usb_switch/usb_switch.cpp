
#include <signal.h>
#include <stdlib.h>
#include <vector>

#include <gpiod.hpp>
#include <iostream>
#include <string.h>
#include <unistd.h>

class gpio_pin {
public:
  gpio_pin(std::string name);
  std::string name;
  char block = 'A';
  std::string chip_name = "gpiochip0";
  int block_line = 0;
  int line = 0;
  gpiod::chip chip;
  gpiod::line gpio_line;
};

std::vector<gpio_pin> pins;
void stop_handler(int s) {
  for (const auto &pin : pins) {
    std::cout << "Turn off " << pin.name << std::endl;
    pin.gpio_line.set_value(0);
    pin.gpio_line.release();
  }
  exit(0);
}

int main(void) {
  gpio_pin pin("GPIO0_D4");

  pins.push_back(pin);
  // ::gpiod::chip chip(pin.chip);
  sleep(5);
  pin.gpio_line.request(
      {"usb_switch", gpiod::line_request::DIRECTION_OUTPUT, 0}, 1);

  struct sigaction sigIntHandler;

  sigIntHandler.sa_handler = stop_handler;
  sigemptyset(&sigIntHandler.sa_mask);
  sigIntHandler.sa_flags = 0;

  sigaction(SIGINT, &sigIntHandler, NULL);
  sigaction(SIGTERM, &sigIntHandler, NULL);
  pause();
}

gpio_pin::gpio_pin(std::string pin_name) {
  this->name = pin_name;
  // name should be GPIOx_yz, with 0<=x<=5, A<=y<=D, 0<=z<=7
  this->chip_name = (std::string)("gpiochip") + pin_name[4];
  this->block = pin_name[6];
  this->block_line = (int)(pin_name[7] - '0');
  this->line = 8 * (this->block - 'A') + this->block_line;
  // std::cout << "cn" << this
  this->chip = ::gpiod::chip(this->chip_name);
  this->gpio_line = chip.get_line(this->line);
  std::cout << "new pin" << pin_name << std::endl;
}