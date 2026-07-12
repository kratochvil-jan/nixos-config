# Migration of postgresql
## Part 1 - database schema

As I was moving immich to NixOS, by default it uses latest postgresql 17.9

However, my old installation was using postgresql 14.22. The database scheme was incompatible.

### 1. Prepare data
The old database directory was renamed to 14/. Copied the directory 17/.

### 2. Context on extensions
Immich was using postgresql extension `vchord`, in both old and new setups.
Nix has a way to package postgresql with variable list of extensions.

We need to build the appropriate derivation for both 14 and 17 with extensions:
note: i happened to do this on arm64 system
```nix-repl
> pkgs = import <nixpkgs> { system = "aarch64-linux"; }
>
> pg14 = pkgs.postgresql_14.withPackages (ps: [ ps.vectorchord ps.pgvector ])
> pg17 = pkgs.postgresql_17.withPackages (ps: [ ps.vectorchord ps.pgvector ])
This derivation produced the following outputs:
  ./repl-result-out -> /nix/store/icfvlg6fnwabrhhgjbv212fbraiv7hws-postgresql-and-plugins-14.22
> :bl pg14
> :bl pg17
This derivation produced the following outputs:
  ./repl-result-out -> /nix/store/wk2c7fb3jdg66iw9gp8j6wnfc1vsbgq2-postgresql-and-plugins-17.9
```

We need to reference these paths in the next commands

### 3. Perform the upgrade
```bash
# sudo -u postgres \
/nix/store/v665xmsfiwzij2x23m7bskmqq850krqa-postgresql-and-plugins-17.9/bin/pg_upgrade \
-b "/nix/store/gvbhfcd2rvhvzg327cah7z91nvivs5k7-postgresql-and-plugins-14.22/bin" \
-B /nix/store/v665xmsfiwzij2x23m7bskmqq850krqa-postgresql-and-plugins-17.9/bin/ \
-d /var/lib/backed-services/14 \
-D /var/lib/backed-services/postgresql/17 \
--old-options "-c shared_preload_libraries=vchord.so"
```

`pg_upgrade` runs a temporary psql server, and it does not seem to pick up the `postgresql.conf`.
That's the reason for the `--old-options` command.

## Part 2 - ownership
Docker instance has separate containers for immich-server and postgresql.

NixOS native setup uses unix sockets, and immich is authenticating using the user `immich`.
However, all tables in the database had the owner set to `postgresql`

### Modifying the database
**All of this was vibe coded**

run the postgresql service and connect to it
```bash
# systemctl start postgresql
# sudo -u postgres psql -d immich
```

psql commands to modify the databases:
```psql
ALTER TABLE public.system_metadata OWNER TO immich;

SELECT schemaname, tablename, tableowner
FROM pg_tables
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY tableowner, tablename;

DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT schemaname, tablename
        FROM pg_tables
        WHERE schemaname = 'public'
    LOOP
        EXECUTE format(
            'ALTER TABLE %I.%I OWNER TO immich',
            r.schemaname,
            r.tablename
        );
    END LOOP;
END $$;

DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT sequence_schema, sequence_name
        FROM information_schema.sequences
        WHERE sequence_schema = 'public'
    LOOP
        EXECUTE format(
            'ALTER SEQUENCE %I.%I OWNER TO immich',
            r.sequence_schema,
            r.sequence_name
        );
    END LOOP;
END $$;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO immich;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO immich;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO immich;

-- print to verify
SELECT tableowner, count(*)
FROM pg_tables
WHERE schemaname = 'public'
GROUP BY tableowner;

SELECT pg_get_userbyid(p.proowner), n.nspname, p.proname, pg_get_function_identity_arguments(p.oid) AS args
        FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname = 'public';


DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT n.nspname, p.proname, pg_get_function_identity_arguments(p.oid) AS args
        FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname = 'public'
    LOOP
        EXECUTE format(
            'ALTER FUNCTION %I.%I(%s) OWNER TO immich',
            r.nspname,
            r.proname,
            r.args
        );
    END LOOP;
END $$;

-- print to verify
SELECT
    pg_get_userbyid(proowner) AS owner,
    count(*)
FROM pg_proc
WHERE pronamespace = 'public'::regnamespace
GROUP BY owner;
```
