class JG_Pawn extends GamePawn; 

//Sprint handling variables
var float SprintSpeed;
var float WalkSpeed;

var float Stamina;
var float SprintTimer;
var float SprintRecoverTimer;
var float Empty;
var bool bSprinting;

//functions for sprinting and stamina system
exec function startSprint()
{
    GroundSpeed = SprintSpeed;
    bSprinting = true;
    if(GroundSpeed == SprintSpeed)
    {
        StopFiring();
        setTimer(SprintTimer, false, 'EmptySprint');
    }
}

exec function stopSprint()
{
    GroundSpeed = WalkSpeed;
}

simulated function EmptySprint()
{
    Stamina = Empty;
    GroundSpeed = WalkSpeed;
    bSprinting = true;
    setTimer(SprintRecoverTimer, false, 'ReplenishStamina');
}

simulated function ReplenishStamina()
{
    Stamina = 10.0;
    bSprinting = false;
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
                //LightShadowMode=LightShadow_ModulateBetter //fixme
                //ShadowFilterQuality=SFQ_High //fixme
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
        
    //defaults for sprinting and stamina system
    GroundSpeed=200.0
    WalkSpeed=280.0
    SprintSpeed=500.0
    SprintTimer=6.0
    SprintRecoverTimer=4.0
    Stamina=6.0
    Empty=1
}