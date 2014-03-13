class JG_EnemyPawn_Guard extends JG_EnemyPawn placeable;

// members for the custom mesh
var SkeletalMesh defaultMesh;
//var MaterialInterface defaultMaterial0;
var AnimTree defaultAnimTree;
var array<AnimSet> defaultAnimSet;
var AnimNodeSequence defaultAnimSeq;
var PhysicsAsset defaultPhysicsAsset;

var JG_EnemyPawn_GuardController GuardController;

var float Speed;

var SkeletalMeshComponent MyMesh;
var bool bplayed;
var Name AnimSetName;
var AnimNodeSequence MyAnimPlayControl;

var () array<NavigationPoint> MyNavigationPoints;

function AddDefaultInventory()
{
    local Weapon newWeapon;
    newWeapon = Spawn(class'UTGameContent.UTWeap_ShockRifle',,,self.Location);
    if (newWeapon != none)
    {
        newWeapon.GiveTo(Controller.Pawn);
        newWeapon.bCanThrow = false; //Doesn't allow default weapon to be thrown
        Controller.ClientSwitchToBestWeapon();
    }
}



simulated function PostBeginPlay()
{
    super.PostBeginPlay();
    //if (Controller == none)
    //  SpawnDefaultController();
    SetPhysics(PHYS_Walking);
    if (GuardController == none)
    {
        GuardController = Spawn(class'JG_EnemyPawn_GuardController', self);
        GuardController.SetPawn(self);     
    }
     
        AddDefaultInventory();

    //I am not using this
    //MyAnimPlayControl = AnimNodeSequence(MyMesh.Animations.FindAnimNode('AnimAttack'));
}

simulated function SetCharacterClassFromInfo(class<UTFamilyInfo> Info)
{
    Mesh.SetSkeletalMesh(defaultMesh);
    //Mesh.SetMaterial(0,defaultMaterial0);
    Mesh.SetPhysicsAsset(defaultPhysicsAsset);
    Mesh.AnimSets=defaultAnimSet;
    Mesh.SetAnimTreeTemplate(defaultAnimTree);

}

defaultproperties
{

    //AnimSetName="ATTACK"
    //AttAcking=true

    defaultMesh=SkeletalMesh'CH_IronGuard_Male.Mesh.SK_CH_IronGuard_MaleA'
    defaultAnimTree=AnimTree'CH_AnimHuman_Tree.AT_CH_Human'
    defaultAnimSet(0)=AnimSet'CH_AnimHuman.Anims.K_AnimHuman_BaseMale'
    defaultPhysicsAsset=PhysicsAsset'CH_AnimCorrupt.mesh.SK_CH_Corrupt_Male_Physics'

    Begin Object Class=SkeletalMeshComponent Name=WPawnSkeletalMeshComponent
        bOwnerNoSee=false
        CastShadow=true

        CollideActors=TRUE
        BlockRigidBody=true
        BlockActors=true
        BlockZeroExtent=true
        //BlockNonZeroExtent=true

        bAllowApproximateOcclusion=true
        bForceDirectLightMap=true
        bUsePrecomputedShadows=false
        //LightEnvironment=MyLightEnvironment
        //Scale=0.5
        SkeletalMesh=SkeletalMesh'CH_IronGuard_Male.Mesh.SK_CH_IronGuard_MaleA'
        AnimSets(0)=AnimSet'CH_AnimHuman.Anims.K_AnimHuman_BaseMale'
        AnimTreeTemplate=AnimTree'CH_AnimHuman_Tree.AT_CH_Human'
        HiddenGame=FALSE
        HiddenEditor=FALSE
    End Object

        Components.Add(WPawnSkeletalMeshComponent)
    mesh=WPawnSkeletalMeshComponent

    Begin Object Name=CollisionCylinder
        CollisionRadius=+0041.000000
        CollisionHeight=+0044.000000
        BlockZeroExtent=false
    End Object
    CylinderComponent=CollisionCylinder
    CollisionComponent=CollisionCylinder

        //Set movement parameters
        bJumpCapable=false
        bCanJump=false
        GroundSpeed=250.0
        MaxStepHeight=50.0

        bAvoidLedges=true
        bStopAtLedges=true

    LedgeCheckThreshold=0.5f

}