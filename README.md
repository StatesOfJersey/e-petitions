# Petitions

This is the code base for the [Jersey States Assembly petitions service][1].

## Setup

We recommend using [Docker Desktop][2] to get setup quickly. If you'd prefer not to use Docker then you'll need Ruby (3.0+), Node (20+) and PostgreSQL (14+) installed.

### Create the databases

```
docker compose run --rm web rake db:setup
```

### Create an admin user

```
docker compose run --rm web rake jpets:add_sysadmin_user
```

### Load the parish list

```
docker compose run --rm web rake jpets:parishes:load
```

### Start the services

```
docker compose up
```

Once the services have started you can access the [front end][3], [back end][4] and any [emails sent][5].

## Tests

Before running any tests the database needs to be prepared:

```
docker compose run --rm web rake db:test:prepare
```

You can run the full test suite using following command:

```
docker compose run --rm web rake
```

Individual specs can be run using the following command:

```
docker compose run --rm web rspec spec/models/site_spec.rb
```

Similarly, individual cucumber features can be run using the following command:

```
docker compose run --rm web cucumber features/suzie_views_a_petition.feature
```

[1]: https://petitions.gov.je
[2]: https://www.docker.com/products/docker-desktop
[3]: http://localhost:3000/
[4]: http://localhost:3000/admin
[5]: http://localhost:1080/
