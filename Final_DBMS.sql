--DROP the FK constraints
GO
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_NAME='FK_cars_car_type')
    ALTER TABLE cars DROP CONSTRAINT FK_cars_car_type
GO
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_NAME='FK_cars_info_car_id')
    ALTER TABLE cars_information DROP CONSTRAINT FK_cars_info_car_id
GO
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_NAME='FK_bids_bid_car_id')
    ALTER TABLE bids DROP CONSTRAINT FK_bids_bid_car_id
GO
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_NAME='FK_bids_bid_user_id')
    ALTER TABLE bids DROP CONSTRAINT FK_bids_bid_user_id
GO
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_NAME='FK_users_score_provider_id')
    ALTER TABLE users_score_lookup DROP CONSTRAINT FK_users_score_provider_id
GO
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_NAME='FK_users_score_user_id')
    ALTER TABLE users_score_lookup DROP CONSTRAINT FK_users_score_user_id
PRINT('Dropped existing constraints')

-- Drop the tables if they already exist
GO
DROP TABLE IF EXISTS cartype_lookup
GO
DROP TABLE IF EXISTS cars
GO
DROP TABLE IF EXISTS cars_information
GO
DROP TABLE IF EXISTS users
GO
DROP TABLE IF EXISTS bid_status_lookup
GO
DROP TABLE IF EXISTS bids
GO
DROP TABLE IF EXISTS score_provider_lookup
GO
DROP TABLE IF EXISTS users_score_lookup
GO
DROP TABLE IF EXISTS users_preference
PRINT('Dropped existing tables')


PRINT('Creating Tables.....')
GO
-- Create the cartype_lookup table used in cars table
USE ist659jprabaka;
CREATE TABLE cartype_lookup (
    [cartype_type] NVARCHAR(10) PRIMARY KEY
)

-- Create the cars table that contains information about cars available at the dealership
GO
CREATE TABLE cars
(
     [car_id] TINYINT NOT NULL IDENTITY(100,1)
    ,[car_name] NVARCHAR(50) NOT NULL
    ,[car_type] NVARCHAR(10) NOT NULL
    ,[car_available] BIT NOT NULL CONSTRAINT DV_cars_car_available DEFAULT 1 -- 0=False, 1=True if car is available or not
    ,[car_asking_price] SMALLMONEY NOT NULL -- Assuming we're only dealing cars that cost <214,748
    ,[car_seller_user_id] TINYINT NOT NULL
    ,[car_buyer_user_id] TINYINT NOT NULL
    ,[car_amount_sold] SMALLMONEY NOT NULL -- Assuming we're only dealing cars that cost <214,748
    ,CONSTRAINT PK_cars_car_id PRIMARY KEY (car_id)
    ,CONSTRAINT FK_cars_car_type FOREIGN KEY (car_type) REFERENCES cartype_lookup(cartype_type)
    ,CONSTRAINT CC_cars_seller_isnot_buyer CHECK (car_seller_user_id != car_buyer_user_id)
)

-- Create the cars_information table that contains detailed information about cars available at the dealership
GO
CREATE TABLE cars_information(
     [cars_info_car_id] TINYINT NOT NULL
    ,[cars_info_car_description] NVARCHAR(500)
    ,[cars_info_car_transmission] CHAR(1) -- A,M Automatic, Manual
    ,[cars_info_car_colour] NVARCHAR(15) NOT NULL
    ,[cars_info_car_yearOfManf] SMALLINT NOT NULL
    ,[cars_info_car_fueltype] CHAR(3) NOT NULL -- GAS,EL,HY
    ,[cars_info_car_mileage_000] SMALLINT NOT NULL
    ,[cars_info_car_noof_prev_owners] TINYINT NOT NULL
    ,[cars_info_car_condition] TINYINT NOT NULL
    ,CONSTRAINT [PK_cars_info_car_id] PRIMARY KEY (cars_info_car_id)
    ,CONSTRAINT [FK_cars_info_car_id] FOREIGN KEY (cars_info_car_id) REFERENCES cars(car_id)
    ,CONSTRAINT [CC_cars_info_car_transmission_lookup] CHECK (cars_info_car_transmission = 'A' OR cars_info_car_transmission = 'M')
    ,CONSTRAINT [CC_cars_info_car_yearOfManf_range] CHECK (cars_info_car_yearOfManf >= 1992 AND cars_info_car_yearOfManf <= 2022)
    ,CONSTRAINT [CC_cars_info_car_fueltype_lookup] CHECK (cars_info_car_fueltype = 'GAS' OR cars_info_car_fueltype = 'ELE' OR cars_info_car_fueltype ='HYB')
    ,CONSTRAINT [CC_cars_info_car_mileage_000_range] CHECK (cars_info_car_mileage_000 > 0 )
    ,CONSTRAINT [CC_cars_info_car_noof_prev_owners] CHECK (cars_info_car_noof_prev_owners > 1)
    ,CONSTRAINT [CC_cars_info_car_condition_range] CHECK (cars_info_car_condition >=0 AND cars_info_car_condition <=5 )

)

-- Create the users table that contains information about users of the dealership
GO
CREATE TABLE users(
     [user_id] TINYINT NOT NULL IDENTITY(1,1)
    ,[user_email] NVARCHAR(75) NOT NULL
    ,[user_firstname] NVARCHAR(50) NOT NULL
    ,[user_lastname] NVARCHAR(50) NOT NULL
    ,[user_zipcode] INT NOT NULL
    ,[user_phonenumber_areacode] SMALLINT NOT NULL -- Takes 6bytes to store a split phone number rather than 8bytes for storing it as a single number
    ,[user_phonenumber_ telephone] INT NOT NULL
    ,[user_credit_score] SMALLINT NOT NULL
    ,CONSTRAINT [PK_users_user_id] PRIMARY KEY (user_id)
    ,CONSTRAINT [UC_users_user_email] UNIQUE (user_email)
    -- CHECK CONSTRAINT FOR user_credit_score to be in a particular range (> some value)
)

-- Create the bid_status_lookup table that contains possible values for bid_status column in the bids table
GO -- Create bid_status_lookup table
CREATE TABLE bid_status_lookup(
     [bid_status_id] BIT NOT NULL PRIMARY KEY
    ,[bid_status_status] CHAR(3) NOT NULL

)

-- Create the bids table that contains information about bids placed on cars
GO -- Create the table
CREATE TABLE bids(
     [bid_id] SMALLINT NOT NULL IDENTITY(1,1)
    ,[bid_user_id] TINYINT NOT NULL
    ,[bid_car_id] TINYINT NOT NULL -- car_id's are assigned from 100-200
    ,[bid_date_time] DATETIME CONSTRAINT DF_bids_bid_date_time_current DEFAULT getdate()
    ,[bid_amount] SMALLMONEY NOT NULL -- Assuming we're only dealing cars that cost <214,748
    ,[bid_status] BIT NOT NULL -- 0=Not ok, 1=Ok
    ,CONSTRAINT [PK_bids_bid_id] PRIMARY KEY (bid_id)
    ,CONSTRAINT [FK_bids_bid_user_id] FOREIGN KEY (bid_user_id) REFERENCES users(user_id)
    ,CONSTRAINT [FK_bids_bid_car_id] FOREIGN KEY (bid_car_id) REFERENCES cars(car_id)
    -- ,CONSTRAINT [DF_bids_bid_date_time_current] DEFAULT bid_datetime (getdate())
    ,CONSTRAINT [CC_bids_bid_status] FOREIGN KEY (bid_status) REFERENCES bid_status_lookup(bid_status_id)
)

-- Create users_score_lookup
GO -- Create the table
CREATE TABLE score_provider_lookup(
    [provider_id] TINYINT NOT NULL PRIMARY KEY
    ,[provider_name] NVARCHAR(30) NOT NULL
)
-- Create users_score_lookup
GO -- Create the table
CREATE TABLE users_score_lookup(
    [users_score_id] TINYINT NOT NULL
    ,[users_score_user_id] TINYINT NOT NULL
    ,[users_score_user score] SMALLINT NOT NULL
    ,[users_score_provider_id] TINYINT NOT NULL
    ,CONSTRAINT [PK_users_score_id] PRIMARY KEY (users_score_id)
    ,CONSTRAINT [FK_users_score_user_id] FOREIGN KEY (users_score_user_id) REFERENCES users(user_id)
    ,CONSTRAINT [FK_users_score_provider_id] FOREIGN KEY (users_score_provider_id) REFERENCES score_provider_lookup(provider_id)
)
-- Create user_preferences
GO -- Create the table
CREATE TABLE users_preference(
    [preference_user_id] TINYINT NOT NULL
    ,[preference_max_price] SMALLMONEY NOT NULL
    ,[preference_color] NVARCHAR(20) NOT NULL
    ,[preference_fueltype] CHAR(3) NOT NULL -- GAS,EL,HY
    ,[preference_transmission] CHAR(1) -- A,M Automatic, Manual
)
PRINT('.....Tables created')

Go 
create View v_cars_based_on_user_preference AS
   select * from users_preference
     join users on users_preference.preference_user_id =  users.user_id 

GO
create View v_cars_info AS
select * from cars
 join cars_information on cars_information.cars_info_car_id = cars.car_id

 GO
 create View v_cars_credit_pre as
 select * from users_preference
 join users on users.user_id = users_preference.preference_user_id

 Create VIEW v_bids_part_car AS
  select bid_id,bid_car_id,bid_amount,bid_status, case when bid_status = 0 then 'Not OK' 
  when bid_status = 1 then 'OK'
  end as bid_status_text from  bids
   join cars on car_id = bid_car_id 