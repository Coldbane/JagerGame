class JG_PlayerController extends GamePlayerController;

var float PreDist; //used for ShoulderCam
var private float viewRotationPitch; // Store View Pitch.

simulated event PostBeginPlay() //This event is triggered when play begins
{
    super.PostBeginPlay();
    `Log("I am alive!"); //This sends the message "I am alive!" to thelog (to see the log, you need to run UDK with the -log switch)
}
//Functions for zooming in and out
exec function NextWeapon() /*The "exec" command tells UDK to ignore what the defined function of NextWeapon is, and use our function declaration here.
We'll go over how to change the function of keys later (if, for instance, you didn't want you use the scroll wheel, but page up and down for zooming instead.)*/
{
if (PlayerCamera.FreeCamDistance < 512) //Checks that the the value FreeCamDistance, which tells the camera how far to offset from the view target, isn't further than we want the camera to go. Change this to your liking.
    {
        `Log("MouseScrollDown"); //Another log message to tell us what's happening in the code
        PlayerCamera.FreeCamDistance += 64*(PlayerCamera.FreeCamDistance/256); /*This portion increases the camera distance.
By taking a base zoom increment (64) and multiplying it by the current distance (d) over 256, we decrease the zoom increment for when the camera is close,
(d < 256), and increase it for when it's far away (d > 256).
Just a little feature to make the zoom feel better. You can tweak the values or take out the scaling altogether and just use the base zoom increment if you like */
    }
}

//dont forget to add ZoomOut() in your UDKInput.ini
exec function ZoomOut()
{
    if (PlayerCamera.FreeCamDistance < 512) //Checking if the distance is at our minimum distance
    {
        `Log("MouseScrollDown");
        PlayerCamera.FreeCamDistance += 64*(PlayerCamera.FreeCamDistance/256); //Once again scaling the zoom for distance
    }
}

//dont forget to add ZoomIn() in your UDKInput.ini
exec function ZoomIn()
{
    if (PlayerCamera.FreeCamDistance > 64) //Checking if the distance is at our minimum distance
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

// Sets aim for gun aling PLAYERs facing orientation
function Rotator GetAdjustAimFor( Weapon W, vector StartFireLoc )
{
    local Rotator adjustedAimRotator;
    
    //Use our adjusted pitch along with our pawn orientation
    adjustedAimRotator.Pitch = viewRotationPitch;
    adjustedAimRotator.Roll = Pawn.Rotation.Roll;
    adjustedAimRotator.Yaw = Pawn.Rotation.Yaw;
    
    return adjustedAimRotator;
}

//Sets PLAYER to move free from CAMERA start 
state PlayerWalking
{
    ignores SeePlayer, HearNoise, Bump;
    
    event NotifyPhysicsVolumeChange (PhysicsVolume NewVolume)
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
            //Update ViewPitch for RemoteClients
            Pawn.SetRemoteViewPitch( Rotation.Pitch );
        }
        
        Pawn.Acceleration = NewAccel;
        
        CheckJumpOrDuck();
    }
        
    function PlayerMove (float DeltaTime)
    {
        local vector X,Y,Z, NewAccel;
        local eDoubleClickDir DoubleClickMove;
        local bool bSaveJump;
        local Rotator DeltaRot, ViewRotation, OldRot, NewRot;;
            
        if( Pawn == None )
        {
            GotoState ('Dead');
        }
        else
        {
            GetAxes(Rotation,X,Y,Z);
                
            //update viewrotation
            ViewRotation = Rotation;
                
            //Calculate Delta to be applied on ViewRotation
            DeltaRot.Yaw = PlayerInput.aTurn;
            DeltaRot.Pitch = PlayerInput.aLookUp;
            ProcessViewRotation( DeltaTime, ViewRotation, DeltaRot );
            SetRotation(ViewRotation);
                
            //update acceleration
            NewAccel = PlayerInput.aForward*X + PlayerInput.aStrafe*Y;
            NewAccel.Z = 0;
                
            //pawn face newaccel direction
            OldRot = Pawn.Rotation;
                
            if( Pawn != None )
            {
                if( NewAccel.X > 0.0 || NewAccel.X < 0.0 || NewAccel.Y > 0.0 || NewAccel.Y < 0.0 )
                    
                NewRot = Rotator(NewAccel);
                else
                NewRot = Pawn.Rotation;
            }
                
            Pawn.FaceRotation(RInterpTo(OldRot,NewRot,Deltatime,90000,true),Deltatime);

            NewAccel = Pawn.AccelRate * Normal(NewAccel);
                
            DoubleClickMove = PlayerInput.CheckForDoubleClickMove( Deltatime/Worldinfo.TimeDilation);
                
            if( bPressedJump && Pawn.CannotJumpNow() )
            {
                bSaveJump = true;
                bPressedJump = false;
            }
            else
            {
                bSaveJump = false;
            }
                
            ProcessMove(Deltatime, NewAccel, DoubleClickMove,Rotation);
                
            bPressedJump = bSaveJump;
        }
            
    }
        
    event BeginState(Name PreviousStateName)
    {
        DoubleClickDir = DCLICK_None;
        bPressedJump = false;
        GroundPitch = 0;
            
        if( Pawn != None )
        {
            Pawn.ShouldCrouch(false);
            if(Pawn.Physics != PHYS_Falling && Pawn.Physics != PHYS_RigidBody) //FIX ME HACK
            Pawn.SetPhysics(PHYS_Walking);
        }
    }
        
    event EndState(Name NextStateName)
    {
        GroundPitch = 0;
            
        if(Pawn != none)
        {
            Pawn.SetRemoteViewPitch(0);
                
            if(bDuck == 0)
            {
                Pawn.ShouldCrouch(false);
            }
        }
    }
}

DefaultProperties
{
    CameraClass = class 'JG_Camera' //Telling the player controller to use your custom camera script
    DefaultFOV=90.f //Telling the player controller what the default field of view (FOV) should be
}