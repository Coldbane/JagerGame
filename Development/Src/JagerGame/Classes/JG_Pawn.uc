class JG_Pawn extends GamePawn; 

// stamina & sprinting variables
var bool        bSprinting;           //Are we Sprinting?
var bool        bCanSprint;           //Can We Sprint?
var bool        bWinded;              //Are we winded?
var float       Stamina;              //How Much Stamina do we have?
var float       MaxStamina;           //Whats the Max amount of Stamina in our Pool?

var float       StaminaTimer;         //How long is the interval between - stam ticks
var int         StaminaLoss;          //How much stamina do we lose per tick of sprinting
var float       StamRegenRate;        //How long is the interval between + stam ticks
var int         StamRegenValue;       //How much stamina do we regen per tick of StamRegenRate
var float       SprintRecoverTimer;   //Regardless of stam, how long will they have to wait between sprints
var float       SprintTimerCount;     //How many seconds of sprint we had left when we stopped sprinting
var float       LastSprint;           //How many seconds of sprint we had left + how many seconds since we last sprinted
var float       ScaledSprintTimer;    //How Long is our sprint timer based upon how much stam we have left

/*************************************************
             Sprinting stuff
***************************************************/

simulated function int GetStaminaCount()
{
    return Stamina;
}

exec function StartSprint()
{
     local float TimeSinceLastSprint;
     local float LogBase;
     ConsoleCommand("Sprint");

     LogBase = 2.512;
     ScaledSprintTimer = (LogE(Stamina)/LogE(LogBase));
     WorldInfo.Game.Broadcast(self, "ScaledSprint Logarithm Calculated");

     // ^Logarithm to perform ScaledSprintTimer = Log(2.512) for (Stamina)
     // Scales our SprintTimer on a curve based upon how much stamina we have left:
                    //Log(2.512) for 100 Stam = 4.99 sec
                    // "    "    for  50 Stam = 4.24 sec
                    // "    "    for  25 Stam = 3.49 sec
                    // "    "    for  15 Stam = 2.94 sec
                    // "    "    for  10 Stam = 2.49 sec
                    // "    "    for   5 Stam = 1.75 sec

     //NOTE: As it is written here, the Logarithm is recalculated everytime the
     //player toggles sprint, so as to avoid issues with players repeatedly
     //'tapping' the sprint key to try and cheat the SprintTimer


    if (Stamina <= StaminaLoss)           //if we have no stam, we can't sprint
     {
        bCanSprint = false;
        StopSprinting();
        return;
     }

     if (Stamina >= StaminaLoss && bWinded != true)     //if we have stam and we aren't winded,
     {                                                  //then we can sprint
        bCanSprint = true;
     }

     if (bCanSprint != false)     //if we can sprint
     {
        bSprinting = true;         //then we are sprinting
        GroundSpeed = 600.0000;

        if (IsTimerActive('TimeSinceSprint'))       //did we sprint recently?
        {
            PauseTimer(true,'TimeSinceSprint');                       //pause the timer
            TimeSinceLastSprint = GetTimerCount('TimeSinceSprint');   //and find out how long we were sprinting
            LastSprint = SprintTimerCount + TimeSinceLastSprint;      //how many seconds of sprint we had left + how many seconds since we last sprinted

            if(LastSprint >= ScaledSprintTimer)        //if its more than ScaledSprintTimer, just use that instead.
            {
                Worldinfo.Game.Broadcast(self, "Sprinting (Full Sprint)");
                StopFiring();
                ClearTimer('Winded');
                ClearTimer('TimeSinceSprint');
                setTimer(StaminaTimer, true, 'DepleteStam');
                setTimer(ScaledSprintTimer, false, 'Winded');
            }
        
           if(LastSprint < ScaledSprintTimer)  //if we have less than ScaledSprintTimer left use that value instead of ScaledSprintTimer
           {
                Worldinfo.Game.Broadcast(self, "Sprinting (LastSprint < ScaledSprintTimer)");
                StopFiring();
                setTimer(StaminaTimer, true, 'DepleteStam');
                setTimer(LastSprint, false, 'Winded');
                ClearTimer('TimeSinceSprint');
           }
        }
        else                                //Otherwise, sprint normally
        {
            Worldinfo.Game.Broadcast(self, "Sprinting (No Prev Timer)");
            StopFiring();
            setTimer(StaminaTimer, true, 'DepleteStam');
            setTimer(ScaledSprintTimer, false, 'Winded');
        }
    }
}

exec function StopSprinting()
{
    GroundSpeed = 200;
    bSprinting = false;
    ClearTimer('DepleteStam');
    SetTimer(StamRegenRate, true, 'RegenStam');

    if(IsTimerActive('Winded'))       //How long were we into the winded timer?
    {
     SprintTimerCount = ScaledSprintTimer - (GetTimerCount('Winded'));  //How many seconds of sprint we had left when we stopped
     PauseTimer(true, 'Winded');
     SetTimer(5.0, false, 'TimeSinceSprint');
    }
}

simulated function DepleteStam()
{
  if (Stamina > 0)                 //If we have stam, remove some per second of sprint
  {
  Worldinfo.Game.Broadcast(self, "-5 stam");
  Stamina -= StaminaLoss;
  }

  if (Stamina <= 0)               //If we dont, stop sprinting and clear timers
  {
  StopSprinting();
  bSprinting = false;
  bCanSprint = false;
  Worldinfo.Game.Broadcast(self, "Tried to deplete, but out of Stamina");
  ClearTimer('DepleteStam');
  }
}

simulated function Winded()
{
  bWinded = true;
  Groundspeed = 200.0000;
  bSprinting = false;
  bCanSprint = false;
  Worldinfo.Game.Broadcast(self, "Winded; need to rest a moment");
  ClearTimer('DepleteStam');
  SetTimer(SprintRecoverTimer, false, 'SprintRecovery');       //how long till we can sprint again
  SetTimer(StamRegenRate, true, 'RegenStam');                  //Start stamina regeneration
}

simulated function SprintRecovery()
{
 bCanSprint = true;
 bWinded = false;
 WorldInfo.Game.Broadcast(self, "SprintRecovery, No Longer Winded");
}

simulated function RegenStam()
{
     if(bSprinting)                                 //if we start sprinting, stop regenerating stam
     {
     ClearTimer('RegenStam');
     Worldinfo.Game.Broadcast(self, "Sprint called, Regen Cancelled");
     Return;
     }

     else
     {
       if(Stamina < MaxStamina)                    // if our current stamina is less than our max
       {
       Stamina += StamRegenValue;                    //add Stam regen value every time the RegenStam ticks
       Worldinfo.Game.Broadcast(self, "+1 stam");
       }

       if(Stamina >= MaxStamina)                      //if our stam is full, don't regen and clear the timer
       {
       ClearTimer('RegenStam');
       Worldinfo.Game.Broadcast(self, "Max Stam; killing regen timer");
       }
     }
}



//This lets the pawn tell the PlayerController what Camera Style to set the camera in initially (more on this later).
simulated function name GetDefaultCameraMode(PlayerController RequestedBy)
{
    return 'ThirdPerson';
}

DefaultProperties
{
    Components.Remove(Sprite)
    //Setting up the light environment
    Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
        ModShadowFadeoutTime=0.25
        MinTimeBetweenFullUpdates=0.2
        AmbientGlow=(R=.01,G=.01,B=.01,A=1)
        AmbientShadowColor=(R=0.15,G=0.15,B=0.15)
        //LightShadowMode=LightShadow_ModulateBetter  //FIX ME LightShadow
        //ShadowFilterQuality=SFQ_High //FIX ME ShadowFilter
        bSynthesizeSHLight=TRUE
    End Object
    
    Components.Add(MyLightEnvironment)
    
    //Setting up the mesh and animset components
    Begin Object Class=SkeletalMeshComponent Name=InitialSkeletalMesh
        CastShadow=true
        bCastDynamicShadow=true
        bOwnerNoSee=false
        LightEnvironment=MyLightEnvironment;
        BlockRigidBody=true;
        CollideActors=true;
        BlockZeroExtent=true;
        //What to change if you'd like to use your own meshes and animations
        PhysicsAsset=PhysicsAsset'CH_AnimCorrupt.Mesh.SK_CH_Corrupt_Male_Physics'
        AnimSets(0)=AnimSet'CH_AnimHuman.Anims.K_AnimHuman_AimOffset'
        AnimSets(1)=AnimSet'CH_AnimHuman.Anims.K_AnimHuman_BaseMale'
        AnimTreeTemplate=AnimTree'CH_AnimHuman_Tree.AT_CH_Human'
        SkeletalMesh=SkeletalMesh'CH_LIAM_Cathode.Mesh.SK_CH_LIAM_Cathode'
    End Object
    
    //Setting up a proper collision cylinder
    Mesh=InitialSkeletalMesh;
    Components.Add(InitialSkeletalMesh); 
    CollisionType=COLLIDE_BlockAll
    
    Begin Object Name=CollisionCylinder
        CollisionRadius=+0023.000000
        CollisionHeight=+0050.000000
    End Object
    
    CylinderComponent=CollisionCylinder
    
    //defaults for Stamina and StaminaRecovery
    Stamina=100.0              //How much stam do we have/start with
    MaxStamina=100.0           //Whats the cap on our stamina pool
                               //(NOTE: if changed, the sprint timer will scale unexpectedly;
                               //the base of the logarithm will also need to be adjusted from 2.512)
    StamRegenRate=3.0          //While not sprinting how long between + stam ticks
    StamRegenValue=1.0         //How much + stam per regen tick
    StaminaTimer=1.0           //how long between - stam ticks while sprinting
    SprintRecoverTimer=5.0     //how long do u have to wait between sprints
    StaminaLoss=5.0            //how much stam do we lose per tick while sprinting
    GroundSpeed=200.0
}
