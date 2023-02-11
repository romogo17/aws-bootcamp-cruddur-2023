# Week 0 — Billing and Architecture

## Intro 
- Videos will be recorded in case we need to catch up

## Instructors
- Margaret Valtierra: Solutions Engineering
- Chris Williams: Principal Cloud Solutions Architect
- Shala Warner

## Project Scenario
> There's no such thing as greenfield. _Quite true_ :) 

- Microservice architecture

### Iron triangle
Chose two...
- Scope (features, functionality)
- Cost (budget, resources)
- Time (schedule)

## Architecture

### RRACs
#### REQUIREMENTS
Something that the project must achieve at the end. Technical or business oriented
- verifiable
- monitorable
- traceable
- feasible

#### RISKS
Prevents the project from being successful (must be mitigated), for example:
- SPoFs (Single Point of Failures)
- user commitment
- late delivery

#### ASSUMPTIONS 
Factors held as true for the planning & implementation phases, for example:
- sufficient network bandwith

#### CONSTRAINTS
Policy or technical limitations for the project, for example:
- time
- budget
- vendor selections

### Design
From gathering the RRACs, you create your designs

#### CONCEPTUAL DESIGN ("Napkin Design")
- Created by business stakeholders and architects
- Defines concepts and rules

#### LOGICAL DESIGN
- Defines how the system should be implemented
- Environment without actual names or sizes

#### PHYSICAL DESIGN
- Representationof the actual thing that was built (IPs of servers, ARNs of resources, etc)


### Useful tools

#### ASK "DUMB QUESTIONS"
- Why are we in the room?
- How will we get this amount of work done?
- How will it make money?
- Do we have the skillset needed to make this a reality?

#### PLAY BE-THE-PACKET
- Be as granular as possible. 
- Educates you about the system you're trying to build

#### DOCUMENT EVERYTHING
- What it does, where the staful data resides, where the ephemeral data resides

#### TOGAF
TOGAF is an architecture framework that provides the methods and tools for assisting in the acceptance, production, use, and maintenance of an enterprise architecture.  It is based on an iterative process model supported by best practices and re-usable set of existing architecture assets

- Most popular framework for EA

#### AWS WELL-ARCHITECTED FRAMEWORK
Asks the right questions (from a TOGAF perspective) to highlight blindspots. Naturally falls into the RRAC buckets. Powerful tool in the architect's toolbelt. 

1. Operational excellence
1. Security
1. Reliability
1. Performance efficiency
1. Cost optimization
1. Sustainability


