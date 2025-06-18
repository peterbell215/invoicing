Add a set of tests to the clients_spec.rb file that test: 
- When a client is created, the Paid By drop down should show 'self-paying' and the payee reference field should be hidden.
- By selecting a Payee, the payee reference field should be shown.
- Data entered into the field is correctly written back to the database.

If a client had a payee and a payee reference, but is switched to 'self-paying' then the payee reference should be set
to blank on submitting the form.
