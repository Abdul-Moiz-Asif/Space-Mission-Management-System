/*
=============================================================================
         SPACE MISSION MANAGEMENT SYSTEM (SMMS)
               Database Systems Project
-----------------------------------------------------------------------------
  Submitted to : Ma'am Marukh Saleem
  Submitted by :
    FA24-BCS-123-C  |  Abdul Moiz Asif
    FA24-BCS-060-C  |  Muhammad Abdullah Shahbaz
    
DATED: 11th May, 2026
=============================================================================
*/

CREATE DATABASE SMMS
USE SMMS;
-- =======================================================================
-- SECTION 1: INDEPENDENT ENTITIES (No Foreign Keys)
-- =======================================================================

-- | USERS |
-- Stores the control room staff and agency personnel who operate the system.
-- A user can issue commands, approve them, and receive system notifications.
-- The 'Role' field distinguishes between roles like Mission Controller, Analyst, etc.

CREATE TABLE Users (
    UserID INT IDENTITY(1,1) PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Email VARCHAR(150) UNIQUE NOT NULL,
    PhoneNumber VARCHAR(25),
    Role VARCHAR(100) NOT NULL
);

-- | CELESTIAL BODY |
-- Represents any planet, moon, asteroid, or star that a mission can target.
-- Mass is stored in scientific units (kg) and Gravity in m/s².
-- Each celestial body must have a unique name to avoid targeting ambiguity.

CREATE TABLE CelestialBody (
    BodyID INT IDENTITY(1,1) PRIMARY KEY,
    BodyName VARCHAR(100) NOT NULL UNIQUE,
    Type VARCHAR(50) NOT NULL,
    Mass FLOAT NOT NULL,     
    Gravity FLOAT NOT NULL    
);

-- | ASTRONAUT |
-- Holds the profile of every astronaut registered in the agency.
-- Status tracks their current availability: Active (on mission), Training,
-- On Leave, or Retired. Qualifications are stored in a separate table (1NF).

CREATE TABLE Astronaut (
    AstronautID INT IDENTITY(1,1) PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Rank VARCHAR(60) NOT NULL,
    Status VARCHAR(30) NOT NULL DEFAULT 'Training'
        CHECK (Status IN ('Active','Training','Retired','On Leave'))
);

-- | SPACECRAFT |
-- Represents a physical spacecraft in the agency fleet.
-- Status tracks whether the vessel is currently mission-ready (Active),
-- under repair (Maintenance), in reserve (Standby), or retired (Decommissioned).
-- Capabilities (e.g. "Deep Space Navigation") are stored in a separate table (1NF).

CREATE TABLE Spacecraft (
    SpacecraftID INT IDENTITY(1,1) PRIMARY KEY,
    VesselName VARCHAR(100) UNIQUE NOT NULL,
    Model VARCHAR(100) NOT NULL,
    Status VARCHAR(30) NOT NULL DEFAULT 'Maintenance'
        CHECK (Status IN ('Active','Maintenance','Decommissioned','Standby'))
);

-- | RESOURCE |
-- Acts as the central inventory for all mission supplies (fuel, food, equipment, etc.).
-- Quantity tracks how much is currently in stock; Unit clarifies the measurement
-- (e.g. kg, liters, count). A resource can exist here before ever being assigned to a mission.

CREATE TABLE Resource (
    ResourceID INT IDENTITY(1,1) PRIMARY KEY,
    ResourceName VARCHAR(100) UNIQUE NOT NULL,
    Quantity DECIMAL(12,2) CHECK (Quantity >= 0) DEFAULT 0,
    Unit VARCHAR(30) NOT NULL 
);


-- =======================================================================
-- SECTION 2: DEPENDENT / WEAK ENTITIES & MULTIVALUED ATTRIBUTES
-- =======================================================================

-- | ASTRONAUT QUALIFICATIONS |
-- Resolves the multivalued 'Qualifications' attribute on Astronaut (1NF).
-- Each row represents one qualification (e.g. "EVA Certified", "Pilot") for one astronaut.
-- Deleting an astronaut automatically removes all their qualification records (CASCADE).

CREATE TABLE Astronaut_Qualifications (
    AstronautID INT NOT NULL,
    Qualification VARCHAR(100) NOT NULL,
    CONSTRAINT PK_Astronaut_Qualifications PRIMARY KEY (AstronautID, Qualification),
    CONSTRAINT FK_AstQual_Astronaut FOREIGN KEY (AstronautID) REFERENCES Astronaut(AstronautID) ON DELETE CASCADE
);

-- | SPACECRAFT CAPABILITIES |
-- Resolves the multivalued 'Capabilities' attribute on Spacecraft (1NF).
-- Each row represents a single functional capability of a spacecraft
-- (e.g. "Orbital Docking", "Crewed Flight"). Removed if the spacecraft is deleted.

CREATE TABLE Spacecraft_Capabilities (
    SpacecraftID INT NOT NULL,
    Capability VARCHAR(100) NOT NULL,
    CONSTRAINT PK_Spacecraft_Capabilities PRIMARY KEY (SpacecraftID, Capability),
    CONSTRAINT FK_Capability_Spacecraft FOREIGN KEY (SpacecraftID) 
        REFERENCES Spacecraft(SpacecraftID) ON DELETE CASCADE
);

-- | HEALTH RECORD |
-- A weak entity that logs medical vital signs for astronauts over time.
-- Since an astronaut can have multiple records, the PK is a composite of
-- AstronautID + timestamp. Records are deleted if the astronaut is removed.

CREATE TABLE HealthRecord (
    AstronautID INT NOT NULL,
    RecordTimestamp DATETIME NOT NULL DEFAULT GETDATE(),
    HeartRate INT CHECK (HeartRate > 0),
    OxygenLevel DECIMAL(5,2) CHECK (OxygenLevel BETWEEN 0 AND 100),hy n nn l. nq23rrr4
    BloodPressure VARCHAR(20), 
    CONSTRAINT PK_HealthRecord PRIMARY KEY (AstronautID, RecordTimestamp),
    CONSTRAINT FK_Health_Astronaut FOREIGN KEY (AstronautID) REFERENCES Astronaut(AstronautID) ON DELETE CASCADE
);


-- =======================================================================
-- SECTION 3: MISSION & ITS DEPENDENCIES
-- =======================================================================

-- | MISSION |
-- The central entity of the entire system. A Mission defines the objective,
-- timeline, and type (Real or Simulation) of a space operation.
-- Every mission must target exactly one CelestialBody (total participation).
-- EndDate can be NULL while the mission is still active or in planning.

CREATE TABLE Mission (
    MissionID INT IDENTITY(1,1) PRIMARY KEY,
    MissionName VARCHAR(150) UNIQUE NOT NULL,
    Type VARCHAR(20) NOT NULL CHECK (Type IN ('Real', 'Simulation')),
    Status VARCHAR(20) NOT NULL DEFAULT 'Planning' CHECK (Status IN ('Planning','Active','Completed','Aborted','On Hold')),
    StartDate DATE NOT NULL,
    EndDate DATE,
    Description VARCHAR(MAX),
    BodyID INT NOT NULL, 
    CONSTRAINT FK_Mission_CelestialBody FOREIGN KEY (BodyID) REFERENCES CelestialBody(BodyID),
    CONSTRAINT CHK_Mission_Dates CHECK (EndDate IS NULL OR EndDate >= StartDate)
);

-- | TRAJECTORY |
-- Defines the mathematical flight path planned for a specific mission.
-- PathType captures the orbital mechanics used (e.g. "Hohmann Transfer", "Bi-elliptic").
-- EstimatedFuel is the projected fuel consumption in kg for that trajectory.
-- Each trajectory belongs to exactly one mission and is deleted with it.

CREATE TABLE Trajectory (
    TrajectoryID INT IDENTITY(1,1) PRIMARY KEY,
    MissionID INT NOT NULL,
    PathType VARCHAR(100) NOT NULL,
    EstimatedFuel DECIMAL(12,2) CHECK (EstimatedFuel >= 0),
    CalculatedDate DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Trajectory_Mission FOREIGN KEY (MissionID) REFERENCES Mission(MissionID) ON DELETE CASCADE
);

-- | LAUNCH |
-- Records each individual launch event, tying together a Mission, a Spacecraft,
-- and the Trajectory that will be followed. The UNIQUE constraint on
-- (MissionID, SpacecraftID, LaunchDate) prevents duplicate launch entries.
-- LaunchResult is updated after the event from its default 'Scheduled' status.

CREATE TABLE Launch (
    LaunchID INT IDENTITY(1,1) PRIMARY KEY,
    MissionID INT NOT NULL,
    SpacecraftID INT NOT NULL,
    TrajectoryID INT NOT NULL,
    LaunchDate DATETIME NOT NULL,
    LaunchResult VARCHAR(30) DEFAULT 'Scheduled' CHECK (LaunchResult IN ('Success','Failure','Partial Success','Aborted','Scheduled')),
    CONSTRAINT FK_Launch_Mission FOREIGN KEY (MissionID) REFERENCES Mission(MissionID),
    CONSTRAINT FK_Launch_Spacecraft FOREIGN KEY (SpacecraftID) REFERENCES Spacecraft(SpacecraftID),
    CONSTRAINT FK_Launch_Trajectory FOREIGN KEY (TrajectoryID) REFERENCES Trajectory(TrajectoryID),
    CONSTRAINT UQ_Mission_Spacecraft_Launch UNIQUE (MissionID, SpacecraftID, LaunchDate) 
);

-- | COMMAND |
-- Stores instructions or directives sent to a mission by control room users.
-- Priority is rated 1 (highest) to 10 (lowest) for execution ordering.
-- A command always targets exactly one mission (total participation).
-- Approval details are tracked separately in Command_Approval.

CREATE TABLE Command (
    CommandID INT IDENTITY(1,1) PRIMARY KEY,
    MissionID INT NOT NULL,
    InstructionType VARCHAR(100) NOT NULL,
    Priority INT CHECK (Priority BETWEEN 1 AND 10), 
    CONSTRAINT FK_Command_Mission FOREIGN KEY (MissionID) REFERENCES Mission(MissionID) ON DELETE CASCADE
);

-- | NOTIFICATION |
-- Stores system-generated alerts and messages sent to specific users.
-- Every notification must belong to a user (total participation).
-- Status tracks whether the user has read or acted on the notification.

CREATE TABLE Notification (
    NotificationID INT IDENTITY(1,1) PRIMARY KEY,
    UserID INT NOT NULL,
    Message VARCHAR(500) NOT NULL,
    SentTime DATETIME DEFAULT GETDATE(),
    Status VARCHAR(20) DEFAULT 'Unread' CHECK (Status IN ('Sent','Read','Unread','Archived')),
    CONSTRAINT FK_Notification_User FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE
);


-- =======================================================================
-- SECTION 4: ASSOCIATIVE ENTITIES (Resolving M:N Relationships)
-- =======================================================================

-- | COMMAND APPROVAL |
-- Resolves the M:N relationship between Commands and Users for the approval process.
-- A single command can be reviewed by multiple users; one user can approve many commands.
-- AuthorityLevel (1 = highest clearance) records the seniority used to authorize the command.
-- The CHECK constraint ensures a TimeOfDecision is always recorded once a decision is made.

CREATE TABLE Command_Approval (
    CommandID INT NOT NULL,
    UserID INT NOT NULL,
    Decision VARCHAR(20) NOT NULL DEFAULT 'Pending' CHECK (Decision IN ('Issued','Approved','Rejected','Pending','Under Review')),
    TimeOfDecision DATETIME,
    AuthorityLevel INT NOT NULL CHECK (AuthorityLevel BETWEEN 1 AND 10),
    CONSTRAINT PK_Command_Approval PRIMARY KEY (CommandID, UserID),
    CONSTRAINT FK_Approval_Command FOREIGN KEY (CommandID) REFERENCES Command(CommandID) ON DELETE CASCADE,
    CONSTRAINT FK_Approval_User FOREIGN KEY (UserID) REFERENCES Users(UserID),
    CONSTRAINT CHK_Decision_Time CHECK (Decision = 'Pending' OR TimeOfDecision IS NOT NULL)
);

-- | MISSION ASTRONAUT ASSIGNMENT |
-- Resolves the M:N relationship between Missions and Astronauts.
-- Tracks which role each astronaut plays in a specific mission (e.g. "Commander", "Pilot")
-- and their assigned duty shift. An astronaut may be in the system without any assignment.

CREATE TABLE Mission_Astronaut_Assignment (
    MissionID INT NOT NULL,
    AstronautID INT NOT NULL,
    Role VARCHAR(100) NOT NULL,
    DutyShift VARCHAR(50) NOT NULL,
    CONSTRAINT PK_Mission_Astronaut PRIMARY KEY (MissionID, AstronautID),
    CONSTRAINT FK_Assignment_Mission FOREIGN KEY (MissionID) REFERENCES Mission(MissionID) ON DELETE CASCADE,
    CONSTRAINT FK_Assignment_Astronaut FOREIGN KEY (AstronautID) REFERENCES Astronaut(AstronautID)
);

-- | MISSION SPACECRAFT ALLOCATION |
-- Resolves the M:N relationship between Missions and Spacecraft.
-- Tracks which spacecraft are allocated to which missions, and for what time window.
-- AllocationEnd can be NULL if the spacecraft is still actively assigned.
-- A spacecraft may remain in the fleet without being currently allocated (partial participation).

CREATE TABLE Mission_Spacecraft_Allocation (
    MissionID INT NOT NULL,
    SpacecraftID INT NOT NULL,
    AllocationStart DATE NOT NULL,
    AllocationEnd DATE,
    CONSTRAINT PK_Mission_Spacecraft PRIMARY KEY (MissionID, SpacecraftID),
    CONSTRAINT FK_Allocation_Mission FOREIGN KEY (MissionID) REFERENCES Mission(MissionID) ON DELETE CASCADE,
    CONSTRAINT FK_Allocation_Spacecraft FOREIGN KEY (SpacecraftID) REFERENCES Spacecraft(SpacecraftID),
    CONSTRAINT CHK_Allocation_Dates CHECK (AllocationEnd IS NULL OR AllocationEnd > AllocationStart)
);

-- | MISSION RESOURCE SUPPLY |
-- Resolves the M:N relationship between Missions and Resources.
-- Tracks every supply request: what was requested, when, and how much was issued.
-- RequestDate is part of the PK to allow the same resource to be re-supplied to
-- the same mission on different dates (e.g. monthly fuel top-ups).

CREATE TABLE Mission_Resource_Supply (
    MissionID INT NOT NULL,
    ResourceID INT NOT NULL,
    RequestDate DATETIME NOT NULL DEFAULT GETDATE(),
    IssuedQuantity DECIMAL(12,2) NOT NULL CHECK (IssuedQuantity > 0),
    CONSTRAINT PK_Mission_Resource PRIMARY KEY (MissionID, ResourceID, RequestDate),
    CONSTRAINT FK_Supply_Mission FOREIGN KEY (MissionID) REFERENCES Mission(MissionID) ON DELETE CASCADE,
    CONSTRAINT FK_Supply_Resource FOREIGN KEY (ResourceID) REFERENCES Resource(ResourceID)
);


-- =======================================================================
-- SECTION 5: TELEMETRY DATA (Polymorphic-style M:1 Relationships)
-- =======================================================================

-- | TELEMETRY DATA |
-- Logs real-time or transmitted sensor readings from a spacecraft during a mission.
-- Each entry records one parameter (e.g. "Temperature", "Radiation Level") and its value.
-- BodyID is nullable: when populated, it means the telemetry reading is specifically
-- about a celestial body (e.g. surface temperature of Mars), not just the spacecraft itself.

CREATE TABLE TelemetryData (
    TelemetryID INT IDENTITY(1,1) PRIMARY KEY,
    SpacecraftID INT NOT NULL,
    BodyID INT NULL,
    TelemetryTimestamp DATETIME NOT NULL DEFAULT GETDATE(),
    Parameter VARCHAR(100) NOT NULL,
    Value DECIMAL(15,5) NOT NULL,
    CONSTRAINT FK_Telemetry_Spacecraft FOREIGN KEY (SpacecraftID) REFERENCES Spacecraft(SpacecraftID),
    CONSTRAINT FK_Telemetry_CelestialBody FOREIGN KEY (BodyID) REFERENCES CelestialBody(BodyID)
    );

/* 
=============================================================================
   SMMS DATA POPULATION SCRIPT 
=============================================================================
*/

-- 1. Users (Control Room & Leadership)
INSERT INTO Users (Name, Email, PhoneNumber, Role) VALUES
('Sarah Mitchell',    'sarah.mitchell@smms.gov',  '+1-202-555-0101', 'Mission Director'),
('James Okafor',      'james.okafor@smms.gov',    '+1-202-555-0102', 'Flight Controller'),
('Priya Nair',        'priya.nair@smms.gov',      '+1-202-555-0103', 'Systems Engineer'),
('Carlos Vega',       'carlos.vega@smms.gov',     '+1-202-555-0104', 'Communications Officer'),
('Elena Petrova',     'elena.petrova@smms.gov',    '+1-202-555-0105', 'Security Analyst'),
('Marcus Thorne',     'marcus.thorne@smms.gov',   '+1-202-555-0106', 'Chief Scientist'),
('Anya Jenkins',      'anya.jenkins@smms.gov',    '+1-202-555-0107', 'Trajectory Specialist'),
('Viktor Drago',      'viktor.drago@smms.gov',    '+1-202-555-0108', 'Robotics Lead'),
('Sana Malik',        'sana.malik@smms.gov',      '+1-202-555-0109', 'Bio-Medical Director'),
('Leo Sterling',      'leo.sterling@smms.gov',    '+1-202-555-0110', 'AI Ethics Overseer');

-- 2. CelestialBody (Planets, Moons, and Anomalies)
INSERT INTO CelestialBody (BodyName, Type, Mass, Gravity) VALUES
('Mars',      'Planet',       6.39E23,  3.720),
('Europa',    'Moon',         4.80E22,  1.315),
('Titan',     'Moon',         1.35E23,  1.352),
('Ceres',     'Asteroid',     9.39E20,  0.270),
('Venus',     'Planet',       4.87E24,  8.870),
('Enceladus', 'Moon',         1.08E20,  0.113),
('Jupiter',   'Planet',       1.89E27,  24.79),
('Pluto',     'Dwarf Planet', 1.30E22,  0.620),
('Ganymede',  'Moon',         1.48E23,  1.428),
('Proxima b', 'Exoplanet',    7.58E24,  10.70);

-- 3. Astronaut (The Crew)
INSERT INTO Astronaut (Name, Rank, Status) VALUES
('Commander Yusuf Al-Rashid',  'Commander',        'Active'),
('Dr. Mei Lin',                'Science Officer',  'Active'),
('Lt. Dmitri Volkov',          'Pilot',            'Active'),
('Sgt. Amara Diallo',          'Engineer',          'Training'),
('Capt. Hana Kobayashi',       'Captain',          'On Leave'),
('Col. Jack Silas',            'Commander',        'Active'),
('Dr. Alistair Thorne',        'Chief Medical',    'Active'),
('Major Sarah Kim',            'Pilot',            'Active'),
('Specialist Orion Pax',       'Mechanic',         'Training'),
('Gen. Robert Sterling',       'General',          'Retired');
                                                                -- select * from Astronaut
-- 4. Spacecraft (The Fleet)
INSERT INTO Spacecraft (VesselName, Model, Status) VALUES
('Ares I',         'Orion MkV',       'Active'),
('Hermes II',      'Falcon Heavy X',  'Active'),
('Titan Voyager',  'Cassini II',      'Standby'),
('Ceres Probe',    'Dawn MkII',       'Maintenance'),
('Aphrodite',      'Venus Lander I',  'Active'),
('Odyssey 10',     'Deep Space Cruiser','Active'),
('Millennium',     'Light Freighter', 'Standby'),
('Endurance',      'Ranger Class',    'Active'),
('Starhopper',     'Prototype Raptor','Decommissioned'),
('Void Walker',    'Stealth Recon',   'Maintenance');

-- 5. Resource (Inventory & Supplies)
INSERT INTO Resource (ResourceName, Quantity, Unit) VALUES
('Liquid Oxygen',     5000.00, 'liters'),
('Rocket Fuel',      12000.00, 'liters'),
('Food Rations',       800.00, 'kg'),
('Medical Supplies',   150.00, 'kg'),
('Spare Parts',        300.00, 'count'),
('Xenon Gas',          400.00, 'liters'),
('Solar Panels',        25.00, 'count'),
('Uranium Rods',        12.00, 'count'),
('Water Ice',         2500.00, 'liters'),
('Shielding Tiles',    150.00, 'count');

-- 6. Astronaut_Qualifications
INSERT INTO Astronaut_Qualifications (AstronautID, Qualification) VALUES
(1, 'EVA Certified'), 
(2, 'Xenobiology'), 
(3, 'Advanced Piloting'), 
(4, 'Structural Engineering'), 
(5, 'Mission Command'),
(6, 'Combat Tactics'), 
(7, 'Trauma Surgery'), 
(8, 'Orbital Mechanics'),
(9, 'Robotic Repair'), 
(10, 'Strategic Diplomacy');

-- 7. Spacecraft_Capabilities
INSERT INTO Spacecraft_Capabilities (SpacecraftID, Capability) VALUES
(1, 'Deep Space Navigation'), (2, 'Cargo Transport'), (3, 'Atmospheric Entry'),
(4, 'Surface Sampling'), (5, 'High Pressure Landing'),
(6, 'FTL Communication'), (7, 'Rapid Re-entry'), (8, 'Cryo-Sleep Pods'),
(9, 'VTOL Landing'), (10, 'Radar Cloaking');

-- 8. HealthRecord (Biometric Logs)
INSERT INTO HealthRecord (AstronautID, RecordTimestamp, HeartRate, OxygenLevel, BloodPressure) VALUES
(1, '2026-01-10 08:00:00', 72, 98.5, '120/80'),
(2, '2026-01-10 08:15:00', 68, 99.1, '115/75'),
(3, '2026-01-10 08:30:00', 75, 97.8, '122/82'),
(4, '2026-01-10 08:45:00', 80, 96.5, '130/85'),
(5, '2026-01-10 09:00:00', 65, 99.3, '110/70'),
(6, '2026-01-11 10:00:00', 60, 99.9, '118/78'),
(7, '2026-01-11 11:00:00', 70, 98.2, '121/79'),
(8, '2026-01-11 12:00:00', 85, 95.0, '135/90'),
(9, '2026-01-11 13:00:00', 74, 98.8, '120/80'),
(10, '2026-01-11 14:00:00', 62, 97.5, '125/85');

-- 9. Notification (System Alerts)
INSERT INTO Notification (UserID, Message, SentTime, Status) VALUES
(1, 'Mission Alpha launch window confirmed.', '2026-01-15 09:00:00', 'Read'),
(2, 'Trajectory recalculation required.', '2026-01-16 10:30:00', 'Unread'),
(3, 'Systems diagnostic scheduled.', '2026-01-17 11:00:00', 'Sent'),
(4, 'Communication blackout expected.', '2026-01-18 14:00:00', 'Read'),
(5, 'Security clearance updated.', '2026-01-19 16:00:00', 'Archived'),
(6, 'New lifeform detected on Enceladus.', '2026-01-20 04:00:00', 'Unread'),
(7, 'Gravitational anomaly near Jupiter.', '2026-01-21 08:00:00', 'Sent'),
(8, 'Robotic arm malfunction on Ares I.', '2026-01-22 09:15:00', 'Read'),
(9, 'Vaccine protocol successful.', '2026-01-23 10:30:00', 'Read'),
(10, 'Unauthorized access attempt blocked.', '2026-01-24 23:00:00', 'Unread');

-- 10. Mission (The Projects)
INSERT INTO Mission (MissionName, Type, Status, StartDate, EndDate, Description, BodyID) VALUES
('Operation Red Frontier',   'Real',       'Active',    '2026-02-01', '2026-08-01', 'First crewed Mars mission.', 1),
('Europa Deep Scan',         'Real',       'Planning',  '2026-05-15', '2027-01-15', 'Ocean exploration.', 2),
('Titan Atmosphere Study',   'Simulation', 'Planning',  '2026-06-01', '2026-12-01', 'Atmospheric study.', 3),
('Ceres Mineral Survey',     'Real',       'Active',    '2026-03-10', '2026-09-10', 'Asteroid survey.', 4),
('Venus Descent Protocol',   'Simulation', 'On Hold',   '2026-07-01', NULL,         'Landing simulation.', 5),
('Project Ice Breaker',      'Real',       'Planning',  '2026-09-01', '2027-05-01', 'Drilling on Enceladus.', 6),
('Storm Chaser',             'Simulation', 'Active',    '2026-10-01', '2026-11-01', 'Jupiter orbit sim.', 7),
('Underworld Echo',          'Real',       'Planning',  '2027-01-01', '2028-01-01', 'Pluto flyby.', 8),
('Ganymede Colony Alpha',    'Real',       'Active',    '2026-04-01', '2028-04-01', 'Base construction.', 9),
('Interstellar Leap',        'Simulation', 'On Hold',   '2030-01-01', NULL,         'Proxima b probe sim.', 10);

-- 11. Trajectory (Flight Paths)
INSERT INTO Trajectory (MissionID, PathType, EstimatedFuel, CalculatedDate) VALUES
(1, 'Hohmann Transfer',      8500.00, '2025-12-01'), (2, 'Gravity Assist', 7200.00, '2025-12-15'),
(3, 'Direct Ascent',         5100.00, '2026-01-10'), (4, 'Low Energy Transfer', 3800.00, '2026-01-20'),
(5, 'Ballistic Entry',       6400.00, '2026-02-05'), (6, 'Spiral Transfer', 9200.00, '2026-03-01'),
(7, 'Hyperbolic Flyby',      4500.00, '2026-03-15'), (8, 'Slingshot Orbit', 11000.00, '2026-04-01'),
(9, 'Polar Entry',           5800.00, '2026-04-10'), (10, 'Light-sail Drift', 0.00, '2026-05-01');

-- 12. Launch (Flight Events)
INSERT INTO Launch (MissionID, SpacecraftID, TrajectoryID, LaunchDate, LaunchResult) VALUES
(1, 1, 1, '2026-02-01 06:00:00', 'Success'), (2, 2, 2, '2026-05-15 07:30:00', 'Scheduled'),
(3, 3, 3, '2026-06-01 05:00:00', 'Scheduled'), (4, 4, 4, '2026-03-10 08:00:00', 'Success'),
(5, 5, 5, '2026-07-01 10:00:00', 'Scheduled'), (6, 6, 6, '2026-09-01 12:00:00', 'Scheduled'),
(7, 7, 7, '2026-10-01 03:00:00', 'Scheduled'), (8, 8, 8, '2027-01-01 01:00:00', 'Scheduled'),
(9, 9, 9, '2026-04-01 09:00:00', 'Success'), (10, 10, 10, '2030-01-01 11:00:00', 'Scheduled');

-- 13. Command (Ground Control Instructions)
INSERT INTO Command (MissionID, InstructionType, Priority) VALUES
(1, 'Initiate Landing', 1), (1, 'Deploy Relay', 2), (2, 'Subsurface Drill', 1),
(4, 'Mineral Sampling', 3), (5, 'Pressure Sim', 2), (6, 'Bio-Scanner On', 1),
(7, 'Adjust Shielding', 1), (8, 'Imaging Array On', 2), (9, 'Module Docking', 1), (10, 'Cryo-Wakeup', 1);

-- 14. Command_Approval (Decision Logs)
INSERT INTO Command_Approval (CommandID, UserID, Decision, TimeOfDecision, AuthorityLevel) VALUES
(1, 1, 'Approved', '2026-01-20', 1), (2, 2, 'Approved', '2026-01-21', 2),
(3, 3, 'Under Review', '2026-01-22', 3), (4, 4, 'Issued', '2026-01-23', 2),
(5, 5, 'Pending', NULL, 4), (6, 6, 'Approved', '2026-01-25', 1),
(7, 7, 'Rejected', '2026-01-26', 2), (8, 8, 'Approved', '2026-01-27', 3),
(9, 9, 'Approved', '2026-01-28', 1), (10, 10, 'Pending', NULL, 5);

-- 15. Mission_Astronaut_Assignment (Crew Roster)
INSERT INTO Mission_Astronaut_Assignment (MissionID, AstronautID, Role, DutyShift) VALUES
(1, 1, 'Commander', 'Alpha'), 
(1, 2, 'Science Lead', 'Beta'), 
(2, 3, 'Pilot', 'Alpha'),
(4, 4, 'Engineer', 'Gamma'), 
(3, 5, 'Commander', 'Alpha'), 
(6, 6, 'Field Commander', 'Alpha'),
(7, 7, 'Medical Officer', 'Beta'), 
(8, 8, 'Flight Lead', 'Alpha'), 
(9, 9, 'Structural Tech', 'Gamma'),
(10, 10, 'Mission Planner', 'Alpha');

-- 16. Mission_Spacecraft_Allocation (Fleet Deployment)
INSERT INTO Mission_Spacecraft_Allocation (MissionID, SpacecraftID, AllocationStart, AllocationEnd) VALUES
(1, 1, '2026-01-20', '2026-08-01'), (2, 2, '2026-04-01', '2027-01-15'),
(3, 3, '2026-05-15', '2026-12-01'), (4, 4, '2026-02-20', '2026-09-10'),
(5, 5, '2026-06-01', NULL), (6, 6, '2026-08-01', '2027-05-01'),
(7, 7, '2026-09-15', '2026-11-01'), (8, 8, '2026-12-01', '2028-01-01'),
(9, 9, '2026-03-01', '2028-04-01'), (10, 10, '2029-01-01', NULL);

-- 17. Mission_Resource_Supply (Logistics)
INSERT INTO Mission_Resource_Supply (MissionID, ResourceID, RequestDate, IssuedQuantity) VALUES
(1, 1, '2026-01-15', 2000), 
(1, 2, '2026-01-15', 5000), 
(2, 3, '2026-04-01', 300),
(4, 4, '2026-02-20', 50), 
(5, 5, '2026-06-01', 100), 
(6, 6, '2026-08-15', 200),
(7, 7, '2026-09-20', 10), 
(8, 8, '2026-12-10', 4), 
(9, 9, '2026-03-15', 1000),
(10, 10, '2029-11-01', 50);

-- 18. TelemetryData (Live Sensor Feeds)
INSERT INTO TelemetryData (SpacecraftID, BodyID, TelemetryTimestamp, Parameter, Value) VALUES
(1, 1, '2026-02-10', 'Temperature', -63.0), 
(2, 2, '2026-05-20', 'Radiation', 0.052),
(3, NULL, '2026-06-15', 'Fuel Pressure', 145.3), 
(4, 4, '2026-03-15', 'Mineral Density', 3.87),
(5, NULL, '2026-07-10', 'Cabin Pressure', 101.3), 
(6, 6, '2026-10-05', 'Seismic Activity', 0.02),
(7, 7, '2026-11-01', 'Magnetic Field', 420.5), 
(8, 8, '2027-02-14', 'Solar Wind', 12.4),
(9, 9, '2026-05-01', 'Oxygen Purity', 99.2), (10, 10, '2030-05-05', 'Signal Strength', -102.5);

-- ====================================
-- TEST QUERRIES FOR THE DATA 
-- =====================================

-- Q1: Get all missions and their current status
SELECT MissionName, Type, Status, StartDate, EndDate
FROM Mission;
 
-- Q2: Get all active astronauts
SELECT Name, Rank, Status
FROM Astronaut
WHERE Status = 'Active';
 
-- Q3: Get all spacecraft that are not under maintenance
SELECT VesselName, Model, Status
FROM Spacecraft
WHERE Status != 'Maintenance';
 
-- Q4: Get all resources with quantity greater than 500
SELECT ResourceName, Quantity, Unit
FROM Resource
WHERE Quantity > 500;

-- Q5: Get all commands with priority 1 (highest)
SELECT CommandID, InstructionType, Priority
FROM Command
WHERE Priority = 1;
 
-- Q6: Get all astronauts ordered by name alphabetically
SELECT Name, Rank, Status
FROM Astronaut
ORDER BY Name ASC;
 
-- Q7: Get all missions ordered by start date (earliest first)
SELECT MissionName, StartDate, EndDate
FROM Mission
ORDER BY StartDate ASC;
 
-- Q8: Get all telemetry readings ordered by timestamp (most recent first)
SELECT TelemetryID, Parameter, Value, TelemetryTimestamp
FROM TelemetryData
ORDER BY TelemetryTimestamp DESC;
 
 
-- Q9: Get each mission with the celestial body it targets
SELECT M.MissionName, M.Status, CB.BodyName, CB.Type
FROM Mission M
JOIN CelestialBody CB ON M.BodyID = CB.BodyID;
 
-- Q10: Get each astronaut assigned to a mission with their role
SELECT A.Name AS AstronautName, M.MissionName, MAA.Role, MAA.DutyShift
FROM Mission_Astronaut_Assignment MAA
JOIN Astronaut A ON MAA.AstronautID = A.AstronautID
JOIN Mission M ON MAA.MissionID = M.MissionID;
 
-- Q11: Get launch details with mission name and spacecraft name
SELECT M.MissionName, S.VesselName, L.LaunchDate, L.LaunchResult
FROM Launch L
JOIN Mission M ON L.MissionID = M.MissionID
JOIN Spacecraft S ON L.SpacecraftID = S.SpacecraftID;
 
-- Q12: Get all commands with the mission they are issued to
SELECT C.CommandID, C.InstructionType, C.Priority, M.MissionName
FROM Command C
JOIN Mission M ON C.MissionID = M.MissionID
ORDER BY C.Priority ASC;
 
-- Q13: Get all notifications with the user who received them
SELECT U.Name AS RecipientName, N.Message, N.SentTime, N.Status
FROM Notification N
JOIN Users U ON N.UserID = U.UserID;
 
-- Q14: Get telemetry data with spacecraft name and celestial body (if any)
SELECT S.VesselName, CB.BodyName, T.Parameter, T.Value, T.TelemetryTimestamp
FROM TelemetryData T
JOIN Spacecraft S ON T.SpacecraftID = S.SpacecraftID
LEFT JOIN CelestialBody CB ON T.BodyID = CB.BodyID;
 
-- Q15: Get command approval details with user name and command info
SELECT U.Name AS ApproverName, C.InstructionType, CA.Decision, 
       CA.TimeOfDecision, CA.AuthorityLevel
FROM Command_Approval CA
JOIN Users U ON CA.UserID = U.UserID
JOIN Command C ON CA.CommandID = C.CommandID;
  
-- Q16: Count total number of astronauts per status
SELECT Status, COUNT(*) AS TotalAstronauts
FROM Astronaut
GROUP BY Status;
 
-- Q17: Count how many astronauts are assigned to each mission
SELECT M.MissionName, COUNT(MAA.AstronautID) AS TotalAstronauts
FROM Mission_Astronaut_Assignment MAA
JOIN Mission M ON MAA.MissionID = M.MissionID
GROUP BY M.MissionName;
 
-- Q18: Get total fuel estimated across all trajectories
SELECT SUM(EstimatedFuel) AS TotalEstimatedFuel
FROM Trajectory;
 
-- Q19: Get average heart rate across all health records
SELECT AVG(HeartRate) AS AverageHeartRate
FROM HealthRecord;
 
-- Q20: Get total issued quantity of each resource supplied to missions
SELECT R.ResourceName, SUM(MRS.IssuedQuantity) AS TotalIssued, R.Unit
FROM Mission_Resource_Supply MRS
JOIN Resource R ON MRS.ResourceID = R.ResourceID
GROUP BY R.ResourceName, R.Unit;

--============================
-- 4TH DELIVERABLE
--========================
-----------------
-- VIEWS
-----------------

-- 1. VIEW: Mission and its Target

CREATE VIEW MissionTargetView AS
SELECT 
    Mission.MissionName, 
    Mission.Type, 
    Mission.Status, 
    CelestialBody.BodyName AS TargetBody,
    CelestialBody.Type AS BodyType
FROM Mission
JOIN CelestialBody ON Mission.BodyID = CelestialBody.BodyID;

select * from MissionTargetView
where Status = 'Active'


-- 2. VIEW: Misson with its assigned Spacecraft and Launch Date
CREATE VIEW FlightDetails AS
SELECT 
    Launch.LaunchID, 
    Launch.LaunchDate, 
    Mission.MissionName, 
    Spacecraft.VesselName, 
    Spacecraft.Model
FROM Launch
INNER JOIN Mission ON Launch.MissionID = Mission.MissionID
INNER JOIN Spacecraft ON Launch.SpacecraftID = Spacecraft.SpacecraftID;

select * from FlightDetails

-- 3. VIEW: Astronaut Details

CREATE VIEW AstronautDetails AS
SELECT 
    Astronaut.Name AS AstronautName, 
    Astronaut.Rank, 
    Mission.MissionName, 
    Mission_Astronaut_Assignment.Role, 
    Mission_Astronaut_Assignment.DutyShift
FROM Astronaut
INNER JOIN Mission_Astronaut_Assignment ON Astronaut.AstronautID = Mission_Astronaut_Assignment.AstronautID
INNER JOIN Mission ON Mission_Astronaut_Assignment.MissionID = Mission.MissionID;

select * from AstronautDetails

-- 4. VIEW: Critical Commands with the number of approvals
CREATE VIEW CriticalCommandApprovals AS
SELECT 
    Command.CommandID, 
    Command.InstructionType, 
    Command.Priority,
    (
        SELECT COUNT(*) 
        FROM Command_Approval 
        WHERE Command_Approval.CommandID = Command.CommandID
    ) AS TotalAssignedApprovers
FROM Command
WHERE Command.Priority <= 3;
select * from CriticalCommandApprovals

-- 5. VIEW: All supplies that are assigned to a mission
CREATE VIEW AssignedSupplies AS
SELECT 
    Resource.ResourceID,
    Resource.ResourceName, 
    Resource.Quantity AS StockQuantity,
    Resource.Unit
FROM Resource
WHERE Resource.ResourceID IN (
    SELECT Mission_Resource_Supply.ResourceID 
    FROM Mission_Resource_Supply
);

select * from AssignedSupplies

--------------------------
-- PROCEDURES
--------------------------
-- Procedure 1: Briefing on Missions
CREATE PROCEDURE GetMissionBriefing
    @TargetMissionID INT
AS
BEGIN
    SELECT 
        Mission.MissionName, 
        CelestialBody.BodyName AS Target, 
        Spacecraft.VesselName AS AssignedShip,
        Mission.Status
    FROM Mission
    JOIN CelestialBody ON Mission.BodyID = CelestialBody.BodyID
    JOIN Mission_Spacecraft_Allocation ON Mission.MissionID = Mission_Spacecraft_Allocation.MissionID
    JOIN Spacecraft ON Mission_Spacecraft_Allocation.SpacecraftID = Spacecraft.SpacecraftID
    WHERE Mission.MissionID = @TargetMissionID;
END;

exec GetMissionBriefing 1

-- Procedure 2: Trajectories that require more fuel than average
CREATE PROCEDURE GetHighFuelTrajectories
AS
BEGIN
    SELECT Trajectory.TrajectoryID, Trajectory.MissionID, Trajectory.EstimatedFuel
    FROM Trajectory
    WHERE Trajectory.EstimatedFuel > (
        SELECT AVG(Trajectory.EstimatedFuel) 
        FROM Trajectory
    );
END;

exec GetHighFuelTrajectories

-- Procedure 3: Updates status of maintenanced spacecraft to active
CREATE PROCEDURE ReleaseSpacecraftToFleet
    @TargetSpacecraftID INT
AS
BEGIN
    UPDATE Spacecraft
    SET Status = 'Active'
    WHERE SpacecraftID = @TargetSpacecraftID AND Status = 'Maintenance';
END;

exec ReleaseSpacecraftToFleet 4

-- Procedure 4: New spacecraft insertion
CREATE PROCEDURE RegisterNewSpacecraft
    @VesselName VARCHAR(100),
    @Model VARCHAR(100),
    @Status VARCHAR(30)
AS
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM Spacecraft 
        WHERE Spacecraft.VesselName = @VesselName
    )
    BEGIN
        PRINT 'Error: A vessel named ' + @VesselName + ' is already registered in the fleet database.';
    END

    ELSE
    BEGIN
        INSERT INTO Spacecraft (VesselName, Model, Status)
        VALUES (@VesselName, @Model, @Status);
        
    END
END;

exec RegisterNewSpacecraft 'Pegasus I','Galaxy XLR8', 'Active'

-- Procedure 5: AstronautMedicalReport
CREATE PROCEDURE GetAstronautMedicalReport
    @TargetAstronautID INT
AS
BEGIN
    SELECT 
        Astronaut.Name,
        Astronaut.Rank,
        HealthRecord.HeartRate,
        HealthRecord.OxygenLevel,
        HealthRecord.BloodPressure,
        HealthRecord.RecordTimestamp
    FROM Astronaut
    JOIN HealthRecord ON Astronaut.AstronautID = HealthRecord.AstronautID
    WHERE Astronaut.AstronautID = @TargetAstronautID;
END;

exec GetAstronautMedicalReport 1

-------------------------------------
-- TRIGGERS
-------------------------------------
-- 1. TRIGGER: AutoActivateAstronaut (AFTER INSERT)
CREATE TRIGGER AutoActivateAstronaut
ON Mission_Astronaut_Assignment
AFTER INSERT
AS
BEGIN
    UPDATE Astronaut
    SET Status = 'Active'
    WHERE AstronautID = (SELECT AstronautID FROM inserted);
END;


-- 2. TRIGGER: AutoDeductResourceStock (AFTER INSERT)
CREATE TRIGGER AutoDeductResourceStock
ON Mission_Resource_Supply
AFTER INSERT
AS
BEGIN
    UPDATE Resource
    SET Quantity = Resource.Quantity - (SELECT IssuedQuantity FROM inserted)
    WHERE ResourceID = (SELECT ResourceID FROM inserted);
END;


-- 3. TRIGGER: PreventInvalidMissionDates (AFTER INSERT, UPDATE)
CREATE TRIGGER PreventInvalidMissionDates
ON Mission
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM inserted 
        WHERE inserted.EndDate IS NOT NULL AND inserted.EndDate < inserted.StartDate
    )
    BEGIN
        RAISERROR ('Validation Error: Mission EndDate cannot be earlier than StartDate.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;

-- 4. TRIGGER: RestrictTableDropping (FOR DROP_TABLE)
CREATE TRIGGER RestrictTableDropping
ON DATABASE 
FOR DROP_TABLE
AS
BEGIN
    RAISERROR ('Security Lock: Dropping tables is forbidden in this environment.', 16, 1);
    ROLLBACK TRANSACTION;
END;

-- 5. TRIGGER: AuditDatabaseChanges (FOR CREATE_TABLE, ALTER_TABLE)
CREATE TRIGGER AuditDatabaseChanges
ON DATABASE
FOR CREATE_TABLE, ALTER_TABLE
AS
BEGIN
    PRINT 'Database Administration Notice: Schema modification event captured successfully.';
END;


-- ===============================
-- ALL DROP/DELETE/RESEED COMMANDS
-- ===============================

-- 1. Drop Associative Tables (M:N Relationships)
DROP TABLE IF EXISTS Mission_Resource_Supply;
DROP TABLE IF EXISTS Mission_Spacecraft_Allocation;
DROP TABLE IF EXISTS Mission_Astronaut_Assignment;
DROP TABLE IF EXISTS Command_Approval;

-- 2. Drop Telemetry and Notifications
DROP TABLE IF EXISTS TelemetryData;
DROP TABLE IF EXISTS Notification;

-- 3. Drop Mission-Dependent Tables
DROP TABLE IF EXISTS Launch;
DROP TABLE IF EXISTS Command;
DROP TABLE IF EXISTS Trajectory;

-- 4. Drop Weak Entities and Multivalued Attribute Tables
DROP TABLE IF EXISTS HealthRecord;
DROP TABLE IF EXISTS Spacecraft_Capabilities;
DROP TABLE IF EXISTS Astronaut_Qualifications;

-- 5. Drop Main Entities with Foreign Key References
-- (Mission must go before CelestialBody)
DROP TABLE IF EXISTS Mission;

-- 6. Drop Final Independent Entities
DROP TABLE IF EXISTS Resource;
DROP TABLE IF EXISTS Spacecraft;
DROP TABLE IF EXISTS Astronaut;
DROP TABLE IF EXISTS CelestialBody;
DROP TABLE IF EXISTS Users;


DELETE FROM TelemetryData;
DELETE FROM Mission_Resource_Supply;
DELETE FROM Mission_Spacecraft_Allocation;
DELETE FROM Mission_Astronaut_Assignment;
DELETE FROM Command_Approval;
DELETE FROM Notification;
DELETE FROM Launch;
DELETE FROM Command;
DELETE FROM Trajectory;
DELETE FROM HealthRecord;
DELETE FROM Spacecraft_Capabilities;
DELETE FROM Astronaut_Qualifications;
DELETE FROM Mission;
DELETE FROM Resource;
DELETE FROM Spacecraft;
DELETE FROM Astronaut;
DELETE FROM CelestialBody;
DELETE FROM Users;

DBCC CHECKIDENT ('Users', RESEED, 0);
DBCC CHECKIDENT ('CelestialBody', RESEED, 0);
DBCC CHECKIDENT ('Astronaut', RESEED, 0);
DBCC CHECKIDENT ('Spacecraft', RESEED, 0);
DBCC CHECKIDENT ('Resource', RESEED, 0);
DBCC CHECKIDENT ('Mission', RESEED, 0);
DBCC CHECKIDENT ('Trajectory', RESEED, 0);
DBCC CHECKIDENT ('Launch', RESEED, 0);
DBCC CHECKIDENT ('Command', RESEED, 0);
DBCC CHECKIDENT ('Notification', RESEED, 0);
DBCC CHECKIDENT ('TelemetryData', RESEED, 0);