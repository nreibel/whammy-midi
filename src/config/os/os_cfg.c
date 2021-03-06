#include "os.h"
#include "os_cfg.h"
#include "timer.h"
#include "bits.h"
#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/sleep.h>
#include "app.h"
#include "serial.h"
#include "eeprom.h"

BackgroundTask BackgroundTasksList[] =
{
	Serial_BackgroundTask,
	EEPROM_BackgroundTask,
};

static volatile uint32_t currentTimeMs = 0;

ISR(TIMER2_COMPA_vect)
{
	currentTimeMs++;
}

uint32_t Os_GetCurrentTimeMs()
{
	return currentTimeMs;
}

void Os_Sleep()
{
	set_sleep_mode(SLEEP_MODE_IDLE);
	sleep_enable();
	sleep_cpu();

	/*
	 * CPU is sleeping...
	 */

	sleep_disable();
}

void Os_Init()
{
	// Disable all peripherals
	PRR = 0xFF;

	// Enable pullup resistor on all inputs
	DDRB = 0;
	DDRC = 0;
	DDRD = 0;
	PORTB = 0xFF;
	PORTC = 0xFF;
	PORTD = 0xFF;

	// Init Timer2 as 1ms counter with interrupts
	RESET_BIT(PRR, PRTIM2);   // Enable peripheral
	OCR2A  = (F_CPU/8)/1000;  // Count 1000us
	TCNT2  = 0;               // Reset timer value
	TCCR2A = 0x2;             // CTC mode
	TCCR2B = 0x2;             // Set prescaler to 8
	SET_BIT(TIMSK2, OCIE2A);  // Enable interrupt on Compare Match A

	// Enable interrupts
	sei();
}
