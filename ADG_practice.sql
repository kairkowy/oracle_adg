Oracle Data Guard 및 Data Guard Broker 구성 

0. Target DB 환경
-- primary database 
database version 19.3

db_name = sdcat
DB_unique_name = sdcat

-- Standby Datatbase
db_name = sdcat
db_unique_name = sdcat_stby


Service 셋업
## primary 서버와 stanby 서버 동일하게 구성 

## Listener 구성

## Primary DB의 listener.ora 

SID_LIST_LISTENER =
  (SID_LIST =
    (SID_DESC =
      (GLOBAL_DBNAME = sdcat)
      (ORACLE_HOME = /home/oracle/19c)
      (SID_NAME = sdcat)
      (ENVS = "TNS_ADMIN=/home/oracle/19c/network/admin")
    )
    (SID_DESC =
      (GLOBAL_DBNAME = sdcat_stby)
      (ORACLE_HOME = /home/oracle/19c)
      (SID_NAME = sdcat)
      (ENVS = "TNS_ADMIN=/home/oracle/19c/network/admin")
    )
     (SID_DESC =
      (GLOBAL_DBNAME = sdcat_DGMGRL.labs.woko.oraclevcn.com)
      (ORACLE_HOME = /home/oracle/19c)
      (SID_NAME = sdcat)
      (ENVS = "TNS_ADMIN=/home/oracle/19c/network/admin")
    )
    (SID_DESC =
      (GLOBAL_DBNAME = sdcat_stby_DGMGRL.labs.woko.oraclevcn.com)
      (ORACLE_HOME = /home/oracle/19c)
      (SID_NAME = sdcat)
      (ENVS = "TNS_ADMIN=/home/oracle/19c/network/admin")
    )

  )

LISTENER =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS = (PROTOCOL = TCP)(HOST = sdlab2.labs.woko.oraclevcn.com)(PORT = 1521))
      (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1521))
    )
  )


## Standby DB의listener.ora

SID_LIST_LISTENER =
  (SID_LIST =
    (SID_DESC =
      (GLOBAL_DBNAME = sdcat)
      (ORACLE_HOME = /home/oracle/19c)
      (SID_NAME = sdcat)
      (ENVS = "TNS_ADMIN=/home/oracle/19c/network/admin")
    )
    (SID_DESC =
      (GLOBAL_DBNAME = sdcat_stby)
      (ORACLE_HOME = /home/oracle/19c)
      (SID_NAME = sdcat)
      (ENVS = "TNS_ADMIN=/home/oracle/19c/network/admin")
    )
     (SID_DESC =
      (GLOBAL_DBNAME = sdcat_DGMGRL.labs.woko.oraclevcn.com)
      (ORACLE_HOME = /home/oracle/19c)
      (SID_NAME = sdcat)
      (ENVS = "TNS_ADMIN=/home/oracle/19c/network/admin")
    )
    (SID_DESC =
      (GLOBAL_DBNAME = sdcat_stby_DGMGRL.labs.woko.oraclevcn.com)
      (ORACLE_HOME = /home/oracle/19c)
      (SID_NAME = sdcat)
      (ENVS = "TNS_ADMIN=/home/oracle/19c/network/admin")
    )
  )


LISTENER =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS = (PROTOCOL = TCP)(HOST = sdlab5.labs.woko.oraclevcn.com)(PORT = 1521))
      (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1521))
    )
  )

-- 리스너 재시작
lsnrctl stop
lsnrctl start

## tnsnames.ora 구성

## primary 서버와 Standby 서버 동일하게 구성

## Primary DB의 tnsnames.ora  

SDCAT =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = sdlab2.labs.woko.oraclevcn.com)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SID = SD1)
    )
  )

SD1_STBY =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = sdlab5.labs.woko.oraclevcn.com)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SID = SD1)
    )
  )


## Standby DB의 tnsnames.ora  

SD1 =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = sdlab2.labs.woko.oraclevcn.com)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SID = SD1)
    )
  )

SD1_STBY =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = sdlab5.labs.woko.oraclevcn.com)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SID = SD1)
    )
  )


## Net 서비스 상태 확인
tnsping SD1
tnsping SD1_stby

Primary DB 셋업

DB Name 확인

## DG 구성시 Primary, standby db의 DB_UNIQUE_NAME은 유니크해야 함. Primary의 DB_UNUQUE_NAME은 "SD1", Standby의 DB_UNIQUE_NAME은 "SD1_STBY"를 사용할 예정임.

## Primary db name 확인

SQL> show parameter db_name
NAME                                 TYPE        VALUE
------------------------------------ ----------- ------------------------------
db_name                              string      sd2


SQL> show parameter db_unique_name
NAME                                 TYPE        VALUE
------------------------------------ ----------- ------------------------------
db_unique_name                       string      sd2

아카이브 모드 설정

## 아카이브 모드가 아닌 경우는 아카이브 모드로 전환이 필요함

$sqlplus / as sysdba

SQL> SELECT log_mode FROM v$database;

LOG_MODE
------------
ARCHIVELOG

## NOARCHIVE mode 인경우에는 아카리브모드 활성화가  필요함.

SQL> SHUTDOWN IMMEDIATE;
SQL> STARTUP MOUNT;
SQL> ALTER DATABASE ARCHIVELOG;
SQL> ALTER DATABASE OPEN;

로깅 모드 변경

## Data Guard 구성시 반드시 설정 필요. nologging 옵션으로 작업을 하는 경우에도 Redo log를 쓰도록 강제하기 위함.

SQL> ALTER DATABASE FORCE LOGGING;

SQL> ALTER SYSTEM SWITCH LOGFILE;  -- 최소 1번 이상의 로그 스위치가 필요함.

Primary DB DG 환경 설정(Data guard & DG Broker 구성)

SQL> ALTER SYSTEM SET LOG_ARCHIVE_MAX_PROCESSES=10;
SQL> ALTER SYSTEM SET log_archive_config='dg_config=(SD2,SD2_STBY)' SCOPE=both;
SQL> ALTER SYSTEM SET fal_server='SD2_STBY' SCOPE=both;
SQL> ALTER SYSTEM SET fal_client='SD2' SCOPE=both;

플래시백 모드 지정

## 플래시백 모드로 운영하면 Switchover 과정에서 유지관리 효율성을 높일 수 있음

SQL> select flashback_on from v$database;

SQL> ALTER DATABASE FLASHBACK ON;

FLASHBACK_ON
------------------
YES

Switchover 위한 standby log file 추가

## online rego log 중에 가장 큰 사이즈 이상으로 Standby log file 사이즈를 크게 만들어야 함 

## Primary DB서버에서

SQL> conn / as sysdba
SQL> select a.group#,a.member,b.bytes from v$logfile a, v$log b
     where a.group# = b.group# order by 1; 

    GROUP# MEMBER                                                                      BYTES
---------- ---------------------------------------------------------------------- ----------
         1 /home/oracle/orabase/oradata/SD2/redo01.log                             209715200
         2 /home/oracle/orabase/oradata/SD2/redo02.log                             209715200
         3 /home/oracle/orabase/oradata/SD2/redo03.log                             209715200

SQL> ALTER DATABASE ADD STANDBY LOGFILE THREAD 1 GROUP 4 ('/home/oracle/orabase/oradata/SD2/standby_redo01.log') SIZE 200M;
SQL> ALTER DATABASE ADD STANDBY LOGFILE THREAD 1 GROUP 5 ('/home/oracle/orabase/oradata/SD2/standby_redo02.log') SIZE 200M;
SQL> ALTER DATABASE ADD STANDBY LOGFILE THREAD 1 GROUP 6 ('/home/oracle/orabase/oradata/SD2/standby_redo03.log') SIZE 200M;
SQL> ALTER DATABASE ADD STANDBY LOGFILE THREAD 1 GROUP 7 ('/home/oracle/orabase/oradata/SD2/standby_redo04.log') SIZE 200M;

SQL> select group#,member from v$logfile order by 1;
    GROUP# MEMBER
---------- ------------------------------------------------------------
         1 /home/oracle/orabase/oradata/SD1/redo01.log
         2 /home/oracle/orabase/oradata/SD1/redo02.log
         3 /home/oracle/orabase/oradata/SD1/redo03.log
         4 /home/oracle/orabase/oradata/SD1/standby_redo01.log
         5 /home/oracle/orabase/oradata/SD1/standby_redo02.log
         6 /home/oracle/orabase/oradata/SD1/standby_redo03.log
         7 /home/oracle/orabase/oradata/SD1/standby_redo04.log


SQL> ALTER SYSTEM SET standby_file_management='AUTO';


Standby Server 셋업

Standby Database 서버 디렉토리 구성 

$ mkdir -p /home/oracle/orabase/oradata/SD2
$ mkdir -p /home/oracle/orabase/fast_recovery_area/SD2
$ mkdir -p /home/oracle/orabase/admin/sd2/adump

Standby DB 생성

Standby database 생성을 위한 init 파일 생성

$vi /tmp/initsd2.ora

*.db_name='sd2'

save

Standby DB sys 패스워드 파일 생성 

$ orapwd file=/home/oracle/19c/dbs/orapwsd2 password=Welcome1 entries=10 format=12
또는

$ scp oracle@sdlab2:/home/oracle/19c/dbs/orapwsd2 $ORACLE_HOME/dbs/


임시(AUXILIARY)용 Standby Database 인스턴스 생성

## Standby DB서버에서

$ export ORACLE_SID=SD2
$ sqlplus / as sysdba

SQL> startup nomount pfile='/tmp/initsd2.ora'
ORACLE instance started.

Total System Global Area  272628632 bytes
Fixed Size                  8895384 bytes
Variable Size             205520896 bytes
Database Buffers           50331648 bytes
Redo Buffers                7880704 bytes

RMAN Duplicate를 사용한 DB 복제 

Primary DB에서RMAN 복제 수행

### Directory 구성이 Primary, Standby 동일한 경우는 다음과 같이 실행합니다.

$ rman TARGET sys/Welcome1@sd2 AUXILIARY sys/Welcome1@sd2_stby

DUPLICATE TARGET DATABASE
  FOR STANDBY
  FROM ACTIVE DATABASE
  DORECOVER
  SPFILE
    SET db_unique_name='sd2_stby' COMMENT 'Is standby'
    set control_files='/home/oracle/orabase/oradata/SD2/control01.ctl','/home/oracle/orabase/oradata/SD2/control02.ctl'
    set fal_client='sd2_stby'
    set fal_server='sd2'
    set log_archive_config='dg_config=(SD2,SD2_STBY)'
  NOFILENAMECHECK;

### Directory 구성이 Primary, Standby 다른 경우는 Convert가 필요함
$rman TARGET sys/Welcome1@sd21 AUXILIARY sys/Welcome1@sd2

DUPLICATE TARGET DATABASE
  FOR STANDBY
  FROM ACTIVE DATABASE
  DORECOVER
  SPFILE
    SET db_unique_name='sd1_stby' COMMENT 'Is standby'
    set fal_client=’sd1_stby’
    set fal_server=’sd1’
    set log_archive_config='dg_config=(SD1,SD1_STBY)'
    SET db_file_name_convert='/original/directory/path1/','/new/directory/path1/','/original/directory/path2/','/new/directory/path2/'
    SET log_file_name_convert='/original/directory/path1/','/new/directory/path1/','/original/directory/path2/','/new/directory/path2/'
    SET job_queue_processes='0'
  NOFILENAMECHECK;

Finished Duplicate Db at ...

standby DB에서

sqlplus / as sysdba

Managed recovery 시작

SQL> alter database recover managed standby database disconnect from session;

SQL> select name, open_mode, DATABASE_ROLE, SWITCHOVER_STATUS from v$database;

NAME      OPEN_MODE            DATABASE_ROLE    SWITCHOVER_STATUS
--------- -------------------- ---------------- --------------------
sd1     MOUNTED              PHYSICAL STANDBY NOT ALLOWED


READ Only 모드로 standby DB 오픈


SQL> alter database recover managed standby database cancel;
SQL> alter database open;
SQL> alter database recover managed standby database disconnect;

SQL> select name, open_mode, DATABASE_ROLE, SWITCHOVER_STATUS from v$database;

NAME      OPEN_MODE            DATABASE_ROLE    SWITCHOVER_STATUS
--------- -------------------- ---------------- --------------------
sd1     READ ONLY WITH APPLY PHYSICAL STANDBY NOT ALLOWED

Standby DB 를 재기동해서 확인

SQL> startup force

select name, open_mode, DATABASE_ROLE, SWITCHOVER_STATUS from v$database;

NAME      OPEN_MODE            DATABASE_ROLE    SWITCHOVER_STATUS
--------- -------------------- ---------------- --------------------
sd1     READ ONLY            PHYSICAL STANDBY NOT ALLOWED

Standby database를 아카이브 모드로 변경

## 참고 : 아카이브 모드로 운영하는 것이 Switchover에 유용함. Standby DB 모드를 확인해서 아카이브 모드로 운영. 

Standby database의 Flashback 모드 변경

SQL> ALTER DATABASE FLASHBACK ON;

SQL> select flashback_on from v$database;

FLASHBACK_ON
------------------
YES

Standby databse 상태 확인

SQL>  select name, open_mode, DATABASE_ROLE, SWITCHOVER_STATUS from v$database;

NAME      OPEN_MODE            DATABASE_ROLE    SWITCHOVER_STATUS
--------- -------------------- ---------------- --------------------
sd1     READ ONLY            PHYSICAL STANDBY NOT ALLOWED

SQL> show parameter log_archive_config

NAME                                 TYPE        VALUE
------------------------------------ ----------- ------------------------------
log_archive_config                   string      dg_config=(SD2,SD2_STBY)


SQL> show parameter fal_server

NAME                                 TYPE        VALUE
------------------------------------ ----------- ------------------------------
fal_server                           string      sd2
SQL> show parameter fal_client

fal_client                           string      sd2_stby

SQL> SELECT sequence#, first_time, next_time, applied FROM v$archived_log ORDER BY sequence#;
 SEQUENCE# FIRST_TIM NEXT_TIME APPLIED
 SEQUENCE# FIRST_TIM NEXT_TIME APPLIED
---------- --------- --------- ---------
        14 07-DEC-23 07-DEC-23 YES
        15 07-DEC-23 07-DEC-23 YES


DG 브로커 구성

Data Guard Broker 설정

## Primary database & standby database 둘다에 설정

SQL> ALTER SYSTEM SET dg_broker_start=true;  --primary

SQL> ALTER SYSTEM SET dg_broker_start=true;  --Standby 

DG Broker에 Primary, Standby database 등록

$ dgmgrl sys/Welcome1@sd2

DGMGRL> CREATE CONFIGURATION sd2_dg_config AS PRIMARY DATABASE IS sd2 CONNECT IDENTIFIER IS sd2;
Configuration "sd2_dg_config" created with primary database "sd2"

DGMGRL> ADD DATABASE sd2_stby AS CONNECT IDENTIFIER IS sd2_stby MAINTAINED AS PHYSICAL;
Database "sd2_stby" added

--앞쪽의 "sd2_stby"는 Standby database의 db_ubique_name이며, 뒤쪽의 "sd2_stby"는 Net 서비스 명임

DGMGRL> ENABLE CONFIGURATION;  -- 조금 시간이 걸림

DGMGRL> show configuration   -- 1차

Configuration - sd2_dg_config

  Protection Mode: MaxPerformance
  Members:
  sd2      - Primary database
    sd2_stby - Physical standby database
      Warning: ORA-16854: apply lag could not be determined

Fast-Start Failover:  Disabled

Configuration Status:
WARNING   (status updated 21 seconds ago)

DGMGRL> show configuration   -- 2차 일정 시간 경과 

Configuration - sd1_dg_config

  Protection Mode: MaxPerformance
  Members:
  sd1      - Primary database
    sd1_stby - Physical standby database

Fast-Start Failover:  Disabled

Configuration Status:
SUCCESS   (status updated 39 seconds ago)


DGMGRL> show database verbose sd2
생략

DGMGRL> show database verbose sd2_stby
생략


DGMGRL> show database sd2_stby staticConnectidentifier
  StaticConnectIdentifier = '(DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(HOST=sdlab5)(PORT=1521))(CONNECT_DATA=(SERVICE_NAME=sdcats_DGMGRL.labs.woko.oraclevcn.com)(INSTANCE_NAME=sdcat)(SERVER=DEDICATED)))'

DGMGRL> validate static connect identifier for all;
Oracle Clusterware is not configured on database "sdcat".
Connecting to database "sdcat" using static connect identifier "(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=sdlab2.labs.woko.oraclevcn.com)(PORT=1521))(CONNECT_DATA=(SERVICE_NAME=sdcat_DGMGRL.labs.woko.oraclevcn.com)(INSTANCE_NAME=sdcat)(SERVER=DEDICATED)(STATIC_SERVICE=TRUE)))" ...
Succeeded.
The static connect identifier allows for a connection to database "sdcat".

Oracle Clusterware is not configured on database "sdcats".
Connecting to database "sdcats" using static connect identifier "(DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(HOST=sdlab5)(PORT=1521))(CONNECT_DATA=(SERVICE_NAME=sdcats_DGMGRL.labs.woko.oraclevcn.com)(INSTANCE_NAME=sdcat)(SERVER=DEDICATED)(STATIC_SERVICE=TRUE)))" ...
Succeeded.
The static connect identifier allows for a connection to database "sdcats".

Standby Database 상태 확인

SQL> select group#, bytes, status from v$log;
    GROUP#      BYTES STATUS
---------- ---------- ----------------
         1  104857600 UNUSED
         3  104857600 UNUSED
         2  104857600 UNUSED

SQL> select name, open_mode, DATABASE_ROLE,SWITCHOVER_STATUS from v$database;
NAME      OPEN_MODE            DATABASE_ROLE    SWITCHOVER_STATUS
--------- -------------------- ---------------- --------------------
sdcat      READ ONLY WITH APPLY PHYSICAL STANDBY NOT ALLOWED

SQL> SELECT sequence#, first_time, next_time, applied FROM v$archived_log ORDER BY sequence#;
 SEQUENCE# FIRST_TIME         NEXT_TIME          APPLIED
---------- ------------------ ------------------ ---------
         8 08-DEC-20          08-DEC-20          YES
         9 08-DEC-20          08-DEC-20          YES
        10 08-DEC-20          08-DEC-20          NO

-- Applied가 "NO" 인 경우 Standby database를 restart해줌

SQL> shutdown immediate
SQL> startup

SSQL> SELECT sequence#, first_time, next_time, applied FROM v$archived_log ORDER BY sequence#;
 SEQUENCE# FIRST_TIME         NEXT_TIME          APPLIED
---------- ------------------ ------------------ ---------
         7 08-DEC-20          08-DEC-20          YES
         8 08-DEC-20          08-DEC-20          YES
         9 08-DEC-20          08-DEC-20          IN-MEMORY


SQL> select name, open_mode, DATABASE_ROLE,SWITCHOVER_STATUS from v$database;

NAME      OPEN_MODE            DATABASE_ROLE    SWITCHOVER_STATUS
--------- -------------------- ---------------- --------------------
sdcat      READ ONLY WITH APPLY PHYSICAL STANDBY NOT ALLOWED

SQL> select inst_id, process, status, thread#, sequence#, block#, blocks from gv$managed_standby where process in ('RFS','LNS') or process like 'MR%';

   INST_ID PROCESS   STATUS          THREAD#  SEQUENCE#     BLOCK#     BLOCKS
---------- --------- ------------ ---------- ---------- ---------- ----------
         1 MRP0      APPLYING_LOG          1         10        103     430080
         1 RFS       IDLE                  1          0          0          0
         1 RFS       IDLE                  1         10        103          1
         1 RFS       IDLE                  0          0          0          0
         1 RFS       IDLE                  0          0          0          0

-------------------------------------------------------------------------------

Primary DB 상태 조회

SQL> select name, open_mode, DATABASE_ROLE,SWITCHOVER_STATUS from v$database;

NAME      OPEN_MODE            DATABASE_ROLE    SWITCHOVER_STATUS
--------- -------------------- ---------------- --------------------
sdcat      READ WRITE           PRIMARY          TO STANDBY

SQL> SELECT sequence#, first_time, next_time, applied FROM v$archived_log ORDER BY sequence#;

 SEQUENCE# FIRST_TIM NEXT_TIME APPLIED
---------- --------- --------- ---------
         9 07-DEC-23 07-DEC-23 NO
        10 07-DEC-23 07-DEC-23 NO
        11 07-DEC-23 07-DEC-23 NO
        12 07-DEC-23 07-DEC-23 NO
        13 07-DEC-23 07-DEC-23 NO
        14 07-DEC-23 07-DEC-23 NO
        15 07-DEC-23 07-DEC-23 NO
        16 07-DEC-23 07-DEC-23 NO
        16 07-DEC-23 07-DEC-23 YES
        17 07-DEC-23 07-DEC-23 NO
        17 07-DEC-23 07-DEC-23 YES
        18 07-DEC-23 07-DEC-23 NO
        18 07-DEC-23 07-DEC-23 NO

## 참고 : MRP 시작

standby db에서

이미 standby db가 마운트 모드이고 MRP 가 가동중이면

dgmgrl sys/Welcome1@sd1_stby

DGMGRL>edit database sd1_stby set state=apply-off;

DGMGRL>shutdown

DGMGRL>edit database sd1_stby  set state=apply-on;

DGMGRL>startup  <<<<MRP will get started automatically


standby DB 생성 확인 및 환경 구성

7. DG 기능 검증  

DDL, DML shipping 검증

Parimary database에서 테이블, 데이터 생성 
SQL> connect sys/Welcome1@sd1 as sysdba
SQL> create user test identified by test default tablespace users quota unlimited on users;
SQL> grant connect, resource to test;

SQL> conn test/test
SQL> create table t1 as select * from tab;

## Standby DB에서 생성된 테이블 데이터 확인 

SQL> conn test/test

SQL> select * from t1;

Database Switchover 검증

DB 역할 및 상태 확인

##  Primary database에서 상태 확인. "SWITCHOVER_STATUS"가 "TO STANDBY"이면 Switchover가 가능한 상태임
## DG Broker 이용하여 Primary, Standby DB 역할과 상태 확인 해야함.

SQL> conn / as sysdba
SQL> select name, open_mode, DATABASE_ROLE,SWITCHOVER_STATUS from v$database;

NAME      OPEN_MODE            DATABASE_ROLE    SWITCHOVER_STATUS
--------- -------------------- ---------------- --------------------
sdcat      READ WRITE           PRIMARY          TO STANDBY

dgmgrl sys/Welcome1@sd2

DGMGRL> validate database sd2

  Database Role:    Primary database

  Ready for Switchover:  Yes

  Managed by Clusterware:
    sd1:  NO
    Validating static connect identifier for the primary database sd1...
    The static connect identifier allows for a connection to database "sd1".

DGMGRL> validate database sd2_stby

  Database Role:     Physical standby database
  Primary Database:  sd1

  Ready for Switchover:  Yes
  Ready for Failover:    Yes (Primary Running)

  Managed by Clusterware:
    sd1     :  NO
    sd1_stby:  NO
    Validating static connect identifier for the primary database sd1...
    The static connect identifier allows for a connection to database "sd1".

  Log Files Cleared:
    sd1 Standby Redo Log Files:       Cleared
    sd1_stby Online Redo Log Files:   Not Cleared
    sd1_stby Standby Redo Log Files:  Available


스위치오버(역할 변경) 실행

$ dgmgrl sys/Welcome1@sd2

DGMGRL> switchover to sd2_stby
Performing switchover NOW, please wait...
Operation requires a connection to database "sd1_stby"
Connecting ...
Connected to "sdcat_stby"
Connected as SYSDBA.
New primary database "sdcat_stby" is opening...
Operation requires start up of instance "sdcat" on database "sdcat"
Starting instance "sdcat"...
Connected to an idle instance.
ORACLE instance started.
Connected to "sdcat"
Database mounted.
Database opened.
Connected to "sdcat"
Switchover succeeded, new primary is "sdcat_stby"

Primary/Standby database 상태 확인

## 스위치오버로 인해 sdcat_stby가 Primary로 sdcat DB가 Standby로 역할이 변경됨.

DGMGRL> validate database sd2

  Database Role:     Physical standby database
  Primary Database:  sdcat_stby

  Ready for Switchover:  Yes
  Ready for Failover:    Yes (Primary Running)

  Managed by Clusterware:
    sdcat_stby:  NO
    sdcat     :  NO
    Validating static connect identifier for the primary database sdcat_stby...
    The static connect identifier allows for a connection to database "sdcat_stby".

  Standby Apply-Related Information:
    Apply State:      Running
    Apply Lag:        Unknown

    Apply Delay:      0 minutes

  Log Files Cleared:
    sdcat_stby Standby Redo Log Files:  Cleared
    sdcat Online Redo Log Files:        Not Cleared
    sdcat Standby Redo Log Files:       Available

  DGMGRL> /

  Database Role:     Physical standby database
  Primary Database:  sdcat_stby

  Ready for Switchover:  Yes
  Ready for Failover:    Yes (Primary Running)

  Managed by Clusterware:
    sdcat_stby:  NO
    sdcat     :  NO
    Validating static connect identifier for the primary database sdcat_stby...
    The static connect identifier allows for a connection to database "sdcat_stby".


DGMGRL> validate database sd2_stby

  Database Role:    Primary database

  Ready for Switchover:  Yes

  Managed by Clusterware:
    sdcat_stby:  NO
    Validating static connect identifier for the primary database sdcat_stby...
    The static connect identifier allows for a connection to database "sdcat_stby".

## Standby databse 접속. Primary와 Standby 롤이 변경괸 것을 확.

SQL> select name, open_mode, DATABASE_ROLE,SWITCHOVER_STATUS from v$database;

NAME      OPEN_MODE            DATABASE_ROLE    SWITCHOVER_STATUS
--------- -------------------- ---------------- --------------------
SDCAT      READ WRITE           PRIMARY          TO STANDBY

## sdcat database 접속 

$sqlplus / as sysdba
SQL> select name, open_mode, DATABASE_ROLE,SWITCHOVER_STATUS from v$database;

NAME      OPEN_MODE            DATABASE_ROLE    SWITCHOVER_STATUS
--------- -------------------- ---------------- --------------------
SDCAT      READ ONLY WITH APPLY PHYSICAL STANDBY NOT ALLOWED

DB 역할 원복(Switch back)

$dgmgrl sys/Welcome1@sd2_stby

DGMGRL> validate database sd2_stby

  Database Role:    Primary database

  Ready for Switchover:  Yes

  Managed by Clusterware:
    sdcat_stby:  NO
    Validating static connect identifier for the primary database sdcat_stby...
    The static connect identifier allows for a connection to database "sdcat_stby".

DGMGRL> validate database sd2

  Database Role:     Physical standby database
  Primary Database:  sdcat_stby

  Ready for Switchover:  Yes
  Ready for Failover:    Yes (Primary Running)

  Managed by Clusterware:
    sdcat_stby:  NO
    sdcat     :  NO
    Validating static connect identifier for the primary database sdcat_stby...
    The static connect identifier allows for a connection to database "sdcat_stby".

DGMGRL> SWITCHOVER TO sd2;
Performing switchover NOW, please wait...
Operation requires a connection to database "sdcat"
Connecting ...
Connected to "sdcat"
Connected as SYSDBA.
New primary database "sdcat" is opening...
Operation requires start up of instance "sdcat" on database "sdcat_stby"
Starting instance "sdcat"...
Connected to an idle instance.
ORACLE instance started.
Connected to "sdcat_stby"
Database mounted.
Database opened.
Connected to "sdcat_stby"
Switchover succeeded, new primary is "sdcat"

DGMGRL> validate database sd2

  Database Role:    Primary database

  Ready for Switchover:  Yes

  Managed by Clusterware:
    sdcat:  NO
    Validating static connect identifier for the primary database sdcat...
    The static connect identifier allows for a connection to database "sdcat".

DGMGRL> validate database sd2_stby

  Database Role:     Physical standby database
  Primary Database:  sdcat

  Ready for Switchover:  Yes
  Ready for Failover:    Yes (Primary Running)

  Managed by Clusterware:
    sdcat     :  NO
    sdcat_stby:  NO
    Validating static connect identifier for the primary database sdcat...
    The static connect identifier allows for a connection to database "sdcat".

  Log Files Cleared:
    sdcat Standby Redo Log Files:       Cleared
    sdcat_stby Online Redo Log Files:   Not Cleared
    sdcat_stby Standby Redo Log Files:  Available

DB Failover 테스트

## Standby database 상태 확인 

SQL> connect sys/Welcome1

SQL> select name, open_mode, DATABASE_ROLE,SWITCHOVER_STATUS from v$database;

NAME      OPEN_MODE            DATABASE_ROLE    SWITCHOVER_STATUS
--------- -------------------- ---------------- --------------------
sdcat      READ ONLY WITH APPLY PHYSICAL STANDBY NOT ALLOWED
