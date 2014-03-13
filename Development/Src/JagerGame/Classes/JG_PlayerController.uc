class JG_PlayerController extends GamePlayerController;

var Pawn LockTarget;
var bool LockedOn;
var bool PlayerLockedOnTarget;
var JG_EnemyPawn E, R;

var float PreDist;
var private float       viewRotationPitch; // Store View Pitch.

//let us aim in that direction, which our Pawn is facing.
function Rotator GetAdjustedAimFor(Weapon W,vector startFireLoc) 
{ 
    local Rotator adjustedAimRotator;
    
    //use our adjusted pitch along with our Pawns orientation
    adjustedAimRotator.Pitch = viewRotationPitch;
    adjustedAimRotator.Roll = Pawn.Rotation.Roll;
    adjustedAimRotator.Yaw = Pawn.Rotation.Yaw;
    
    return adjustedAimRotator;
} 

//let us control the player and camera seperat from each other
state PlayerWalking
{
    ignores SeePlayer, HearNoise, Bump;

    event NotifyPhysicsVolumeChange( PhysicsVolume NewVolume )
    {
        if ( NewVolume.bWaterVolume && Pawn.bCollideWorld )
        {
            GotoState(Pawn.WaterMovementState);
        }
    }

    function ProcessMove(float DeltaTime, vector NewAccel, eDoubleClickDir DoubleClickMove, rotator DeltaRot)
    {
        if( Pawn == None )
        {
            return;
        }

        if (Role == ROLE_Authority)
        {
        // Update ViewPitch for remote clients
        Pawn.SetRemoteViewPitch( Rotation.Pitch );
        }

        Pawn.Acceleration = NewAccel;
        CheckJumpOrDuck();
    }

    function PlayerMove( float DeltaTime )
    {
        local vector X,Y,Z, NewAccel;
        local eDoubleClickDir DoubleClickMove;
        local bool bSaveJump;
        local Rotator DeltaRot, ViewRotation, OldRot, NewRot;;

        if( Pawn == None )
        {
            GotoState('Dead');
        }
        else
        {
            GetAxes(Rotation,X,Y,Z);

            //update viewrotation
            ViewRotation = Rotation;
            // Calculate Delta to be applied on ViewRotation
            DeltaRot.Yaw = PlayerInput.aTurn;
            DeltaRot.Pitch = PlayerInput.aLookUp;
            ProcessViewRotation( DeltaTime, ViewRotation, DeltaRot );
            SetRotation(ViewRotation);
            
            // Store adjusted pitch in our class variable so we can use it outside of the method.
            self.viewRotationPitch = ViewRotation.Pitch;

            // Update acceleration.
            NewAccel = PlayerInput.aForward*X + PlayerInput.aStrafe*Y;
            NewAccel.Z = 0;
            // pawn face newaccel direction //

            //===
            OldRot = Pawn.Rotation;
            if( Pawn != None )
            { 
                if( NewAccel.X > 0.0 || NewAccel.X < 0.0 || NewAccel.Y > 0.0 || NewAccel.Y < 0.0 )
                NewRot = Rotator(NewAccel);
                else
                NewRot = Pawn.Rotation;
            }
            Pawn.FaceRotation(RInterpTo(OldRot,NewRot,Deltatime,90000,true),Deltatime);
            //===

            NewAccel = Pawn.AccelRate * Normal(NewAccel);
            DoubleClickMove = PlayerInput.CheckForDoubleClickMove( DeltaTime/WorldInfo.TimeDilation );
            bDoubleJump = false;

            if( bPressedJump && Pawn.CannotJumpNow() )
            {
                bSaveJump = true;
                bPressedJump = false;
            }
            else
            {
            bSaveJump = false;
            }

            ProcessMove(DeltaTime, NewAccel, DoubleClickMove,Rotation);

            bPressedJump = bSaveJump;
        }
    }

    event BeginState(Name PreviousStateName)
    {
        DoubleClickDir = DCLICK_None;
        bPressedJump = false;
        GroundPitch = 0;
        if ( Pawn != None )
        {
            Pawn.ShouldCrouch(false);
            if (Pawn.Physics != PHYS_Falling && Pawn.Physics != PHYS_RigidBody) // FIXME HACK!!!
            Pawn.SetPhysics(PHYS_Walking);
        }
    }

    event EndState(Name NextStateName)
    {
        GroundPitch = 0;
        if ( Pawn != None )
        {
            Pawn.SetRemoteViewPitch( 0 );
            if ( bDuck == 0 )
            {
                Pawn.ShouldCrouch(false);
            }
        }
    }

    Begin:
}

//face the enemy if player use LockOn
event PlayerTick( float DeltaTime)
{
    local Rotator LockRotation;
    local vector TargetPos, thePlayerPos;
    
    TargetPos = LockTarget.location;
    thePlayerPos = Pawn.location;
    
    super.Playertick(Deltatime);
    
    if(PlayerLockedOnTarget == true)
    {
        LockRotation = rotator(TargetPos - thePlayerPos);
        Pawn.FaceRotation(LockRotation, DeltaTime);
    }
}

//functions for LockOn
exec function LockOn()
{
    //local CrystPawn_Guard E;   // E will be used in our itterator to find enemies in range and living
   
    if(LockedOn == true)
    {
        //Worldinfo.Game.Broadcast(self, "LOCKON");
        //I chose to use overlapping actors as it is simple to use, other itterators can be used
        //You must also pass the possessed pawn's location into the test to find enemies in range
        foreach OverlappingActors(class'JG_EnemyPawn',E,1024.0,Pawn.Location)
        {
            //We test to see if the enemy found is alive
            if(E.Health > 0)
            {
                //If the enemy is alive, we store the enemy and exit
                //Using return here forces the look the exit without testing another enemy
                //Consider changing this to test for the closest enemy as well
                //as this only returns the first enemy alive and not the closest
                LockedOn=false;
                LockTarget=E;
                PlayerLockedOnTarget = true;
                return;
            }
        }
        //Finally, we test to see if we do in fact have an enemy stored.
        //I use the LockedOn boolean in other functions to be sure lockon abilities
        //Don't work unless actually targetting something
        if(LockTarget !=none )
        {
            LockedOn=true;
            PlayerLockedOnTarget = false;
        }
    }
    if(LockedOn == false)
    {
        //This just clears our locked on flags and the TargetEnemy pointer;
        //Worldinfo.Game.Broadcast(self, "LOCKOFF");
        LockTarget=none;
        LockedOn=true;
        PlayerLockedOnTarget = false;
    }
}

exec function CycleTargets()
{
    if(PlayerLockedOnTarget == true)
    {
        foreach OverlappingActors(class'JG_EnemyPawn',R,1024.0,Pawn.Location)
        {
            if(R.Health > 0)
            {
                if(LockTarget == E)
                {
                    LockTarget=R;
                }
                else if(LockTarget == R)
                {
                    LockTarget=E;
                }
            }
        }
    }
}

//Functions for zooming in and out
exec function ZoomOut() //The "exec" command tells UDK to ignore what the defined function of NextWeapon is, and use our function declaration here. We'll go over how to change the function of keys later (if, for instance, you didn't want you use the scroll wheel, but page up and down for zooming instead.)
{
    if (PlayerCamera.FreeCamDistance < 300) //Checks that the the value FreeCamDistance, which tells the camera how far to offset from the view target, isn't further than we want the camera to go. Change this to your liking.
    {
        `Log("MouseScrollDown"); //Another log message to tell us what's happening in the code
        PlayerCamera.FreeCamDistance += 64*(PlayerCamera.FreeCamDistance/256); //This portion increases the camera distance. By taking a base zoom increment (64) and multiplying it by the current distance (d) over 256, we decrease the zoom increment for when the camera is close, (d < 256), and increase it for when it's far away (d > 256). Just a little feature to make the zoom feel better. You can tweak the values or take out the scaling altogether and just use the base zoom increment if you like 
    }
}

exec function ZoomIn()
{
    if (PlayerCamera.FreeCamDistance > 80) //Checking if the distance is at our minimum distance
    {
        `Log("MouseScrollUp");
        PlayerCamera.FreeCamDistance -= 64*(PlayerCamera.FreeCamDistance/256); //Once again scaling the zoom for distance
    }
}

exec function ShoulderCam() // Declaring our ShoulderCam function that we bound to
{
    `Log("Shoulder Camera"); // Yet another log...
    PreDist = PlayerCamera.FreeCamDistance; //Storing our previous camera distance...
    JG_Camera(PlayerCamera).CameraStyle = 'ShoulderCam'; //Type casting our camera script to access the variable CameraStyle
}

exec function ReturnCam() //This is called on release of left shift
{
    `Log("Main Camera");
    PlayerCamera.FreeCamDistance = PreDist; // Restoring the previous camera distance
    JG_Camera(PlayerCamera).CameraStyle = 'ThirdPerson'; // Restoring the previous camera style
}

event Possess(Pawn inPawn, bool bVehicleTransition)
{
    Super.Possess(inPawn, bVehicleTransition);
    LockedOn = true;
    PlayerLockedOnTarget = false;
}




simulated event PostBeginPlay() //This event is triggered when play begins
{
    super.PostBeginPlay();
    `Log("I am alive!"); //This sends the message "I am alive!" to thelog (to see the log, you need to run UDK with the -log switch)
}

DefaultProperties
{
    CameraClass = class 'JG_Camera' //Telling the player controller to use your custom camera script
    DefaultFOV=90.f //Telling the player controller what the default field of view (FOV) should be
}