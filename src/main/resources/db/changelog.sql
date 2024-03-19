--liquibase formatted sql

--changeset kmpk:init_schema
DROP TABLE IF EXISTS USER_ROLE;
DROP TABLE IF EXISTS CONTACT;
DROP TABLE IF EXISTS MAIL_CASE;
DROP
SEQUENCE IF EXISTS MAIL_CASE_ID_SEQ;
DROP TABLE IF EXISTS PROFILE;
DROP TABLE IF EXISTS TASK_TAG;
DROP TABLE IF EXISTS USER_BELONG;
DROP
SEQUENCE IF EXISTS USER_BELONG_ID_SEQ;
DROP TABLE IF EXISTS ACTIVITY;
DROP
SEQUENCE IF EXISTS ACTIVITY_ID_SEQ;
DROP TABLE IF EXISTS TASK;
DROP
SEQUENCE IF EXISTS TASK_ID_SEQ;
DROP TABLE IF EXISTS SPRINT;
DROP
SEQUENCE IF EXISTS SPRINT_ID_SEQ;
DROP TABLE IF EXISTS PROJECT;
DROP
SEQUENCE IF EXISTS PROJECT_ID_SEQ;
DROP TABLE IF EXISTS REFERENCE;
DROP
SEQUENCE IF EXISTS REFERENCE_ID_SEQ;
DROP TABLE IF EXISTS ATTACHMENT;
DROP
SEQUENCE IF EXISTS ATTACHMENT_ID_SEQ;
DROP TABLE IF EXISTS USERS;
DROP
SEQUENCE IF EXISTS USERS_ID_SEQ;

create table PROJECT
(
    ID bigserial primary key,
    CODE        varchar(32)   not null
        constraint UK_PROJECT_CODE unique,
    TITLE       varchar(1024) not null,
    DESCRIPTION varchar(4096) not null,
    TYPE_CODE   varchar(32)   not null,
    STARTPOINT  timestamp,
    ENDPOINT    timestamp,
    PARENT_ID   bigint,
    constraint FK_PROJECT_PARENT foreign key (PARENT_ID) references PROJECT (ID) on delete cascade
);

create table MAIL_CASE
(
    ID bigserial primary key,
    EMAIL     varchar(255) not null,
    NAME      varchar(255) not null,
    DATE_TIME timestamp    not null,
    RESULT    varchar(255) not null,
    TEMPLATE  varchar(255) not null
);

create table SPRINT
(
    ID bigserial primary key,
    STATUS_CODE varchar(32)   not null,
    STARTPOINT  timestamp,
    ENDPOINT    timestamp,
    TITLE       varchar(1024) not null,
    PROJECT_ID  bigint        not null,
    constraint FK_SPRINT_PROJECT foreign key (PROJECT_ID) references PROJECT (ID) on delete cascade
);

create table REFERENCE
(
    ID bigserial primary key,
    CODE       varchar(32)   not null,
    REF_TYPE   smallint      not null,
    ENDPOINT   timestamp,
    STARTPOINT timestamp,
    TITLE      varchar(1024) not null,
    AUX        varchar,
    constraint UK_REFERENCE_REF_TYPE_CODE unique (REF_TYPE, CODE)
);

create table USERS
(
    ID bigserial primary key,
    DISPLAY_NAME varchar(32)  not null
        constraint UK_USERS_DISPLAY_NAME unique,
    EMAIL        varchar(128) not null
        constraint UK_USERS_EMAIL unique,
    FIRST_NAME   varchar(32)  not null,
    LAST_NAME    varchar(32),
    PASSWORD     varchar(128) not null,
    ENDPOINT     timestamp,
    STARTPOINT   timestamp
);

create table PROFILE
(
    ID                 bigint primary key,
    LAST_LOGIN         timestamp,
    LAST_FAILED_LOGIN  timestamp,
    MAIL_NOTIFICATIONS bigint,
    constraint FK_PROFILE_USERS foreign key (ID) references USERS (ID) on delete cascade
);

create table CONTACT
(
    ID    bigint       not null,
    CODE  varchar(32)  not null,
    VALUE varchar(256) not null,
    primary key (ID, CODE),
    constraint FK_CONTACT_PROFILE foreign key (ID) references PROFILE (ID) on delete cascade
);

create table TASK
(
    ID bigserial primary key,
    TITLE         varchar(1024) not null,
    DESCRIPTION   varchar(4096) not null,
    TYPE_CODE     varchar(32)   not null,
    STATUS_CODE   varchar(32)   not null,
    PRIORITY_CODE varchar(32)   not null,
    ESTIMATE      integer,
    UPDATED       timestamp,
    PROJECT_ID    bigint        not null,
    SPRINT_ID     bigint,
    PARENT_ID     bigint,
    STARTPOINT    timestamp,
    ENDPOINT      timestamp,
    constraint FK_TASK_SPRINT foreign key (SPRINT_ID) references SPRINT (ID) on delete set null,
    constraint FK_TASK_PROJECT foreign key (PROJECT_ID) references PROJECT (ID) on delete cascade,
    constraint FK_TASK_PARENT_TASK foreign key (PARENT_ID) references TASK (ID) on delete cascade
);

create table ACTIVITY
(
    ID bigserial primary key,
    AUTHOR_ID     bigint not null,
    TASK_ID       bigint not null,
    UPDATED       timestamp,
    COMMENT       varchar(4096),
--     history of task field change
    TITLE         varchar(1024),
    DESCRIPTION   varchar(4096),
    ESTIMATE      integer,
    TYPE_CODE     varchar(32),
    STATUS_CODE   varchar(32),
    PRIORITY_CODE varchar(32),
    constraint FK_ACTIVITY_USERS foreign key (AUTHOR_ID) references USERS (ID),
    constraint FK_ACTIVITY_TASK foreign key (TASK_ID) references TASK (ID) on delete cascade
);

create table TASK_TAG
(
    TASK_ID bigint      not null,
    TAG     varchar(32) not null,
    constraint UK_TASK_TAG unique (TASK_ID, TAG),
    constraint FK_TASK_TAG foreign key (TASK_ID) references TASK (ID) on delete cascade
);

create table USER_BELONG
(
    ID bigserial primary key,
    OBJECT_ID      bigint      not null,
    OBJECT_TYPE    smallint    not null,
    USER_ID        bigint      not null,
    USER_TYPE_CODE varchar(32) not null,
    STARTPOINT     timestamp,
    ENDPOINT       timestamp,
    constraint FK_USER_BELONG foreign key (USER_ID) references USERS (ID)
);
create unique index UK_USER_BELONG on USER_BELONG (OBJECT_ID, OBJECT_TYPE, USER_ID, USER_TYPE_CODE);
create index IX_USER_BELONG_USER_ID on USER_BELONG (USER_ID);

create table ATTACHMENT
(
    ID bigserial primary key,
    NAME        varchar(128)  not null,
    FILE_LINK   varchar(2048) not null,
    OBJECT_ID   bigint        not null,
    OBJECT_TYPE smallint      not null,
    USER_ID     bigint        not null,
    DATE_TIME   timestamp,
    constraint FK_ATTACHMENT foreign key (USER_ID) references USERS (ID)
);

create table USER_ROLE
(
    USER_ID bigint   not null,
    ROLE    smallint not null,
    constraint UK_USER_ROLE unique (USER_ID, ROLE),
    constraint FK_USER_ROLE foreign key (USER_ID) references USERS (ID) on delete cascade
);

--changeset kmpk:populate_data
--============ References =================
insert into REFERENCE (CODE, TITLE, REF_TYPE)
-- TASK
values ('task', 'Task', 2),
       ('story', 'Story', 2),
       ('bug', 'Bug', 2),
       ('epic', 'Epic', 2),
-- SPRINT_STATUS
       ('planning', 'Planning', 4),
       ('active', 'Active', 4),
       ('finished', 'Finished', 4),
-- USER_TYPE
       ('author', 'Author', 5),
       ('developer', 'Developer', 5),
       ('reviewer', 'Reviewer', 5),
       ('tester', 'Tester', 5),
-- PROJECT
       ('scrum', 'Scrum', 1),
       ('task_tracker', 'Task tracker', 1),
-- CONTACT
       ('skype', 'Skype', 0),
       ('tg', 'Telegram', 0),
       ('mobile', 'Mobile', 0),
       ('phone', 'Phone', 0),
       ('website', 'Website', 0),
       ('vk', 'VK', 0),
       ('linkedin', 'LinkedIn', 0),
       ('github', 'GitHub', 0),
-- PRIORITY
       ('critical', 'Critical', 7),
       ('high', 'High', 7),
       ('normal', 'Normal', 7),
       ('low', 'Low', 7),
       ('neutral', 'Neutral', 7);

insert into REFERENCE (CODE, TITLE, REF_TYPE, AUX)
-- MAIL_NOTIFICATION
values ('assigned', 'Assigned', 6, '1'),
       ('three_days_before_deadline', 'Three days before deadline', 6, '2'),
       ('two_days_before_deadline', 'Two days before deadline', 6, '4'),
       ('one_day_before_deadline', 'One day before deadline', 6, '8'),
       ('deadline', 'Deadline', 6, '16'),
       ('overdue', 'Overdue', 6, '32'),
-- TASK_STATUS
       ('todo', 'ToDo', 3, 'in_progress,canceled'),
       ('in_progress', 'In progress', 3, 'ready_for_review,canceled'),
       ('ready_for_review', 'Ready for review', 3, 'review,canceled'),
       ('review', 'Review', 3, 'in_progress,ready_for_test,canceled'),
       ('ready_for_test', 'Ready for test', 3, 'test,canceled'),
       ('test', 'Test', 3, 'done,in_progress,canceled'),
       ('done', 'Done', 3, 'canceled'),
       ('canceled', 'Canceled', 3, null);

--changeset gkislin:change_backtracking_tables

alter table SPRINT rename COLUMN TITLE to CODE;
alter table SPRINT
    alter column CODE type varchar (32);
alter table SPRINT
    alter column CODE set not null;
create unique index UK_SPRINT_PROJECT_CODE on SPRINT (PROJECT_ID, CODE);

ALTER TABLE TASK
    DROP COLUMN DESCRIPTION;
ALTER TABLE TASK
    DROP COLUMN PRIORITY_CODE;
ALTER TABLE TASK
    DROP COLUMN ESTIMATE;
ALTER TABLE TASK
    DROP COLUMN UPDATED;

--changeset ishlyakhtenkov:change_task_status_reference

delete
from REFERENCE
where REF_TYPE = 3;
insert into REFERENCE (CODE, TITLE, REF_TYPE, AUX)
values ('todo', 'ToDo', 3, 'in_progress,canceled'),
       ('in_progress', 'In progress', 3, 'ready_for_review,canceled'),
       ('ready_for_review', 'Ready for review', 3, 'in_progress,review,canceled'),
       ('review', 'Review', 3, 'in_progress,ready_for_test,canceled'),
       ('ready_for_test', 'Ready for test', 3, 'review,test,canceled'),
       ('test', 'Test', 3, 'done,in_progress,canceled'),
       ('done', 'Done', 3, 'canceled'),
       ('canceled', 'Canceled', 3, null);

--changeset gkislin:users_add_on_delete_cascade

alter table ACTIVITY
    drop constraint FK_ACTIVITY_USERS,
    add constraint FK_ACTIVITY_USERS foreign key (AUTHOR_ID) references USERS (ID) on delete cascade;

alter table USER_BELONG
    drop constraint FK_USER_BELONG,
    add constraint FK_USER_BELONG foreign key (USER_ID) references USERS (ID) on delete cascade;

alter table ATTACHMENT
    drop constraint FK_ATTACHMENT,
    add constraint FK_ATTACHMENT foreign key (USER_ID) references USERS (ID) on delete cascade;

--changeset valeriyemelyanov:change_user_type_reference

delete
from REFERENCE
where REF_TYPE = 5;
insert into REFERENCE (CODE, TITLE, REF_TYPE)
-- USER_TYPE
values ('project_author', 'Author', 5),
       ('project_manager', 'Manager', 5),
       ('sprint_author', 'Author', 5),
       ('sprint_manager', 'Manager', 5),
       ('task_author', 'Author', 5),
       ('task_developer', 'Developer', 5),
       ('task_reviewer', 'Reviewer', 5),
       ('task_tester', 'Tester', 5);

--changeset apolik:refactor_reference_aux

-- TASK_TYPE
delete
from REFERENCE
where REF_TYPE = 3;
insert into REFERENCE (CODE, TITLE, REF_TYPE, AUX)
values ('todo', 'ToDo', 3, 'in_progress,canceled|'),
       ('in_progress', 'In progress', 3, 'ready_for_review,canceled|task_developer'),
       ('ready_for_review', 'Ready for review', 3, 'in_progress,review,canceled|'),
       ('review', 'Review', 3, 'in_progress,ready_for_test,canceled|task_reviewer'),
       ('ready_for_test', 'Ready for test', 3, 'review,test,canceled|'),
       ('test', 'Test', 3, 'done,in_progress,canceled|task_tester'),
       ('done', 'Done', 3, 'canceled|'),
       ('canceled', 'Canceled', 3, null);

--changeset ishlyakhtenkov:change_UK_USER_BELONG

drop index UK_USER_BELONG;
create unique index UK_USER_BELONG on USER_BELONG (OBJECT_ID, OBJECT_TYPE, USER_ID, USER_TYPE_CODE) where ENDPOINT is null;

--changeset filippova:populate db
-- populate users
DELETE
FROM USERS;
alter
    sequence USERS_ID_SEQ restart with 1;
insert into USERS (EMAIL, PASSWORD, FIRST_NAME, LAST_NAME, DISPLAY_NAME)
values ('user@gmail.com', '{noop}password', 'userFirstName', 'userLastName', 'userDisplayName'),
       ('admin@gmail.com', '{noop}admin', 'adminFirstName', 'adminLastName', 'adminDisplayName'),
       ('guest@gmail.com', '{noop}guest', 'guestFirstName', 'guestLastName', 'guestDisplayName'),
       ('manager@gmail.com', '{noop}manager', 'managerFirstName', 'managerLastName', 'managerDisplayName'),
       ('taras@gmail.com', '{noop}password', 'Тарас', 'Шевченко', '@taras'),
       ('petlura@gmail.com', '{noop}password', 'Симон', 'Петлюра', '@epetl'),
       ('moroz_a@gmail.com', '{noop}password', 'Александр', 'Мороз', '@Moroz93'),
       ('antonio.nest@gmail.com', '{noop}password', 'Антон', 'Нестеров', '@antonio_nest'),
       ('i.franko@gmail.com', '{noop}password', 'Иван', 'Франко', '@ifranko'),
       ('g.skovoroda@gmail.com', '{noop}password', 'Григорий', 'Сковорода', '@Gregory24'),
       ('arsh.and@gmail.com', '{noop}password', 'Андрей', 'Арш', '@arsh01'),
       ('squirrel2011@gmail.com', '{noop}password', 'Леся', 'Иванюк', '@SmallSquirrel'),
       ('nikk24@gmail.com', '{noop}password', 'Николай', 'Никулин', '@nikk'),
       ('artem711@gmail.com', '{noop}password', 'Артем', 'Запорожец', '@Artt'),
       ('max.pain@gmail.com', '{noop}password', 'Максим', 'Дудник', '@MaxPain'),
       ('admin@aws.co', '{noop}password', 'test', 'admin', '@testAdmin');

-- 0 DEV
-- 1 ADMIN
-- 2 MANAGER
DELETE
FROM USER_ROLE;
insert into USER_ROLE (USER_ID, ROLE)
values (1, 0),
       (2, 0),
       (2, 1),
       (4, 2),
       (5, 0),
       (6, 0),
       (7, 0),
       (8, 0),
       (9, 0),
       (10, 0),
       (11, 0),
       (12, 0),
       (13, 0),
       (14, 0),
       (15, 1),
       (16, 1);


insert into PROFILE (ID, LAST_FAILED_LOGIN, LAST_LOGIN, MAIL_NOTIFICATIONS)
values (1, null, null, 49),
       (2, null, null, 14);

insert into CONTACT (ID, CODE, VALUE)
values (1, 'skype', 'userSkype'),
       (1, 'mobile', '+01234567890'),
       (1, 'website', 'user.com'),
       (2, 'github', 'adminGitHub'),
       (2, 'tg', 'adminTg'),
       (2, 'vk', 'adminVk');

delete
from ATTACHMENT;
alter
    sequence ATTACHMENT_ID_SEQ restart with 1;
insert into ATTACHMENT (name, file_link, object_id, object_type, user_id, date_time)
values ('Снимок экрана 1.png', './attachments/project/1_Снимок экрана 1.png', 2, 0, 4, '2023-05-04 22:28:50.215429'),
       ('Снимок экрана 2.png', './attachments/project/2_Снимок экрана 2.png', 2, 0, 4, '2023-05-04 22:28:53.687600'),
       ('Ежедневный-чеклист.xlsx', './attachments/project/3_Ежедневный-чеклист.xlsx', 2, 0, 4,
        '2023-05-04 22:31:15.166547'),
       ('Снимок экрана 1.png', './attachments/task/1_Снимок экрана 1.png', 41, 2, 4, '2023-05-04 22:28:53.687600'),
       ('Снимок экрана 2.png', './attachments/task/2_Снимок экрана 2.png', 41, 2, 4, '2023-05-04 22:28:50.215429'),
       ('Ежедневный-чеклист.xlsx', './attachments/task/3_Ежедневный-чеклист.xlsx', 38, 2, 4,
        '2023-05-04 22:28:50.215429');
alter
    sequence ATTACHMENT_ID_SEQ restart with 1000;


-- populate tasks
delete
from TASK;
alter
    sequence TASK_ID_SEQ restart with 1;
delete
from SPRINT;
alter
    sequence SPRINT_ID_SEQ restart with 1;
delete
from PROJECT;
alter
    sequence PROJECT_ID_SEQ restart with 1;
delete
from ACTIVITY;
alter
    sequence ACTIVITY_ID_SEQ restart with 1;

insert into PROJECT (code, title, description, type_code, parent_id)
values ('JiraRush', 'JiraRush', '«Mini-JIRA» app : project management system tutorial app', 'task_tracker', null),
       ('Test_Project', 'Test Project', 'Just test project', 'task_tracker', null),
       ('Test_Project_2', 'Test Project 2', 'Just test project 2', 'task_tracker', null),
       ('JiraRush sub', 'JiraRush subproject', 'subproject', 'task_tracker', 1);
alter
    sequence PROJECT_ID_SEQ restart with 1000;

insert into SPRINT (status_code, startpoint, endpoint, code, project_id)
values ('active', null, null, 'Sprint-2', 1),
       ('finished', '2023-04-09 08:05:10', '2023-04-29 16:48:34', 'Sprint-1', 2),
       ('finished', '2023-04-03 12:14:11', '2023-04-18 17:03:41', 'Sprint-2', 2),
       ('active', '2023-04-05 14:25:43', '2023-06-10 13:00:00', 'Sprint-3', 2),
       ('active', null, null, 'Sprint-1', 4);
alter
    sequence SPRINT_ID_SEQ restart with 1000;

---- project 1 -------------
INSERT INTO TASK (TITLE, TYPE_CODE, STATUS_CODE, PROJECT_ID, SPRINT_ID, STARTPOINT)
values ('Data', 'epic', 'in_progress', 1, 1,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Trees', 'epic', 'in_progress', 1, 1,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('UI', 'epic', 'in_progress', 1, 1, now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Sprint', 'epic', 'in_progress', 1, 1,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Project', 'epic', 'in_progress', 1, 1,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Task', 'epic', 'in_progress', 1, 1,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Attachments', 'story', 'in_progress', 1, 1,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Dashboard', 'epic', 'in_progress', 1, 1,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Report of Sprint (UI)', 'story', 'in_progress', 1, 1,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Organizational-architectural', 'epic', 'in_progress', 1, 1,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'), ---- project 2 -------------
       ('Title', 'task', 'todo', 2, 2, now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'todo', 2, 2, now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'in_progress', 2, 2,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'in_progress', 2, 2,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'in_progress', 2, 2,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'test', 2, 2, now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'done', 2, 2, now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'done', 2, 2, now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'canceled', 2, 2, now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'ready_for_test', 2, 2,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'in_progress', 2, 3,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'in_progress', 2, 3,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'in_progress', 2, 3,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'test', 2, 3, now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'test', 2, 3, now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'test', 2, 3, now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'done', 2, 3, now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'done', 2, 3, now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'ready_for_test', 2, 3,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'ready_for_test', 2, 3,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'todo', 2, 4, now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'story', 'todo', 2, 4, now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'bug', 'todo', 2, 4, now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'todo', 2, 4, now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'todo', 2, 4, now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'epic', 'in_progress', 2, 4,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'ready_for_review', 2, 4,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'ready_for_review', 2, 4,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'story', 'ready_for_test', 2, 4,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'review', 2, 4, now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'bug', 'review', 2, 4, now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'test', 2, 4, now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'epic', 'test', 2, 4, now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'done', 2, 4, now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'done', 2, 4, now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'story', 'done', 2, 4, now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'bug', 'done', 2, 4, now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'canceled', 2, 4, now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'todo', 2, 2, now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'todo', 2, 2, now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'in_progress', 2, 2,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'in_progress', 2, 2,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'in_progress', 2, 2,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'test', 2, 2, now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'done', 2, 2, now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'done', 2, 2, now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'canceled', 2, 2, now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'ready_for_test', 2, 2,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'in_progress', 2, 3,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'in_progress', 2, 3,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'in_progress', 2, 3,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'test', 2, 3, now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'test', 2, 3, now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'test', 2, 3, now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'done', 2, 3, now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'done', 2, 3, now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'ready_for_test', 2, 3,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'ready_for_test', 2, 3,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'todo', 2, 4, now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'story', 'todo', 2, 4, now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'bug', 'todo', 2, 4, now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'todo', 2, 4, now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'todo', 2, 4, now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'epic', 'in_progress', 2, 4,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'ready_for_review', 2, 4,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'ready_for_review', 2, 4,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'story', 'ready_for_test', 2, 4,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'review', 2, 4, now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'bug', 'review', 2, 4, now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'test', 2, 4, now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'epic', 'test', 2, 4, now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'done', 2, 4, now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'done', 2, 4, now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'story', 'done', 2, 4, now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'bug', 'done', 2, 4, now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Title', 'task', 'canceled', 2, 4, now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('subproject sprint task', 'epic', 'in_progress', 4, 5,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('subproject backlog task', 'epic', 'in_progress', 4, null,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds');

INSERT INTO TASK (TITLE, TYPE_CODE, STATUS_CODE, PROJECT_ID, SPRINT_ID, PARENT_ID, STARTPOINT)
values ('Add role manager and filters in security', 'task', 'done', 1, 1, 1,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Add users from task-timing', 'task', 'ready_for_review', 1, 1, 1,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Add tasks-2 in DB', 'task', 'in_progress', 1, 1, 1,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Remove reference with USER_TYPE IN (3,4,5)', 'task', 'in_progress', 1, 1, 1,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('REST API for trees', 'task', 'in_progress', 1, 1, 2,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Drawing in trees', 'task', 'in_progress', 1, 1, 2,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Context menu', 'task', 'in_progress', 1, 1, 2,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Reassignment sprint', 'task', 'in_progress', 1, 1, 2,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Add task, subtask, sprint, subsprint', 'task', 'in_progress', 1, 1, 2,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Make layout for view TitleTo', 'task', 'in_progress', 1, 1, 3,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Make layout for edit TitleTo', 'task', 'in_progress', 1, 1, 3,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Fix header-fragment', 'task', 'ready_for_review', 1, 1, 3,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('REST API', 'task', 'in_progress', 1, 1, 4,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Tests', 'task', 'in_progress', 1, 1, 4,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('UI view, mock button to dashboard', 'task', 'in_progress', 1, 1, 4,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('UI edit', 'task', 'in_progress', 1, 1, 4,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('REST API', 'task', 'in_progress', 1, 1, 5,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Tests', 'task', 'in_progress', 1, 1, 5,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('UI view, mock button to dashboard', 'task', 'in_progress', 1, 1, 5,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('UI edit', 'task', 'in_progress', 1, 1, 5,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('REST API', 'task', 'in_progress', 1, 1, 6,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Tests', 'task', 'in_progress', 1, 1, 6,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('UI view, mock button to dashboard', 'task', 'in_progress', 1, 1, 6,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('UI edit', 'task', 'in_progress', 1, 1, 6,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('UI view add to Task, mock button to dashboard', 'task', 'in_progress', 1, 1, 6,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('UI edit add to Task', 'task', 'in_progress', 1, 1, 6,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Edit changelog with changes of Task model', 'task', 'in_progress', 1, 1, 6,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('REST API: changeStatus', 'task', 'in_progress', 1, 1, 6,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Make columns with tasks', 'task', 'in_progress', 1, 1, 8,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('UI tab of tasks', 'task', 'in_progress', 1, 1, 8,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Context mune', 'task', 'in_progress', 1, 1, 8,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Duration, count of tasks, elapsed time', 'task', 'in_progress', 1, 1, 9,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Meeting, dividing tasks', 'task', 'in_progress', 1, 1, 10,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Refactoring packages', 'task', 'in_progress', 1, 1, 10,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Refactoring tasks', 'task', 'in_progress', 1, 1, 10,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Subproject sprint subtask', 'task', 'in_progress', 4, 5, 87,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds'),
       ('Subproject backlog subtask', 'task', 'in_progress', 4, null, 88,
        now() + random() * interval '5 minutes' + random() * interval '20 seconds');
alter
    sequence TASK_ID_SEQ restart with 1000;

---task 1------
INSERT INTO ACTIVITY(AUTHOR_ID, TASK_ID, UPDATED, COMMENT, TITLE, DESCRIPTION, ESTIMATE, TYPE_CODE, STATUS_CODE,
                     PRIORITY_CODE)
values (6, 1, '2023-05-15 09:05:10', null, 'Data', null, 3, 'epic', 'in_progress', 'low'),
       (5, 1, '2023-05-15 12:25:10', null, 'Data', null, null, null, null, 'normal'),
       (6, 1, '2023-05-15 14:05:10', null, 'Data', null, 4, null, null, null), ---task 118----
       (11, 118, '2023-05-16 10:05:10', null, 'UI tab of tasks', null, 4, 'task', 'in_progress', 'normal'),
       (5, 118, '2023-05-16 11:10:10', null, 'UI tab of tasks', null, null, null, null, 'high'),
       (11, 118, '2023-05-16 12:30:10', null, 'UI tab of tasks', null, 2, null, null, null);


