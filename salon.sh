#! /bin/bash

printf "~~~~~ MY SALON ~~~~~\n\n"
printf "Welcome to My Salon, how can I help you?\n\n"

print_services() {
  psql --username=freecodecamp --dbname=salon -Atqc "SELECT service_id || ') ' || name FROM services ORDER BY service_id;"
}

print_services
while true; do
  if ! read SERVICE_ID_SELECTED; then
    exit 0
  fi

  if [[ "$SERVICE_ID_SELECTED" =~ ^[0-9]+$ ]]; then
    SERVICE_NAME=$(psql --username=freecodecamp --dbname=salon -Atqc "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED;")
  else
    SERVICE_NAME=""
  fi

  if [[ -n "$SERVICE_NAME" ]]; then
    break
  fi

  printf "\nI could not find that service. What would you like today?\n"
  print_services
done

printf "\nWhat's your phone number?\n"
if ! read CUSTOMER_PHONE; then
  exit 0
fi

CUSTOMER_ID=$(psql --username=freecodecamp --dbname=salon -v phone="$CUSTOMER_PHONE" -Atq <<'SQL'
SELECT customer_id FROM customers WHERE phone = :'phone';
SQL
)
if [[ -z "$CUSTOMER_ID" ]]; then
  printf "\nI don't have a record for that phone number, what's your name?\n"
  if ! read CUSTOMER_NAME; then
    exit 0
  fi
  CUSTOMER_ID=$(psql --username=freecodecamp --dbname=salon -v phone="$CUSTOMER_PHONE" -v name="$CUSTOMER_NAME" -Atq <<'SQL'
INSERT INTO customers (phone, name) VALUES (:'phone', :'name') RETURNING customer_id;
SQL
  )
fi

CUSTOMER_NAME=$(psql --username=freecodecamp --dbname=salon -Atqc "SELECT name FROM customers WHERE customer_id = $CUSTOMER_ID;")
printf "\nWhat time would you like your %s, %s?\n" "$SERVICE_NAME" "$CUSTOMER_NAME"
if ! read SERVICE_TIME; then
  exit 0
fi

psql --username=freecodecamp --dbname=salon -v customer_id="$CUSTOMER_ID" -v service_id="$SERVICE_ID_SELECTED" -v service_time="$SERVICE_TIME" -q <<'SQL'
INSERT INTO appointments (customer_id, service_id, time) VALUES (:'customer_id', :'service_id', :'service_time');
SQL
printf "\nI have put you down for a %s at %s, %s.\n" "$SERVICE_NAME" "$SERVICE_TIME" "$CUSTOMER_NAME"