// From the book:
//
// Scripting Recipes for Second Life
// by Jeff Heaton (Encog Dod in SL)
// ISBN: 160439000X
// Copyright 2007 by Heaton Research, Inc.
//
// This script may be freely copied and modified so long as this header
// remains unmodified.
//
// For more information about this book visit the following web site:
//
// http://www.heatonresearch.com/articles/series/22/

integer CHANNEL = 56;
integer total;
key claimed_key = NULL_KEY;
string claimed_name;
integer index;
key query;
float percent;
integer check_group = FALSE;
integer timeout = 0;

generalParticleEmitterOn()                
{   
    llParticleSystem([                   
        PSYS_PART_FLAGS , 0 
    //| PSYS_PART_BOUNCE_MASK       //Bounce on object's z-axis
    //| PSYS_PART_WIND_MASK           //Particles are moved by wind
    | PSYS_PART_INTERP_COLOR_MASK   //Colors fade from start to end
    | PSYS_PART_INTERP_SCALE_MASK   //Scale fades from beginning to end
    | PSYS_PART_FOLLOW_SRC_MASK     //Particles follow the emitter
    //| PSYS_PART_FOLLOW_VELOCITY_MASK//Particles are created at the velocity of the emitter
    //| PSYS_PART_TARGET_POS_MASK   //Particles follow the target
    | PSYS_PART_EMISSIVE_MASK       //Particles will glow
    //| PSYS_PART_TARGET_LINEAR_MASK//Undocumented--Sends particles in straight line?
    ,
    
    //PSYS_SRC_TARGET_KEY , NULL_KEY,//The particles will head towards the specified key
    //Select one of the following for a pattern:
    //PSYS_SRC_PATTERN_DROP                 Particles start at emitter with no velocity
    //PSYS_SRC_PATTERN_EXPLODE              Particles explode from the emitter
    //PSYS_SRC_PATTERN_ANGLE                Particles are emitted in a 2-D angle
    //PSYS_SRC_PATTERN_ANGLE_CONE           Particles are emitted in a 3-D cone
    //PSYS_SRC_PATTERN_ANGLE_CONE_EMPTY     Particles are emitted everywhere except for a 3-D cone
    
    PSYS_SRC_PATTERN,           PSYS_SRC_PATTERN_EXPLODE
    
    ,PSYS_SRC_TEXTURE,           ""           //UUID of the desired particle texture, or inventory name
    ,PSYS_SRC_MAX_AGE,           0.0            //Time, in seconds, for particles to be emitted. 0 = forever
    ,PSYS_PART_MAX_AGE,          10.0            //Lifetime, in seconds, that a particle lasts
    ,PSYS_SRC_BURST_RATE,        1.0            //How long, in seconds, between each emission
    ,PSYS_SRC_BURST_PART_COUNT,  1              //Number of particles per emission
    ,PSYS_SRC_BURST_RADIUS,      10.0           //Radius of emission
    ,PSYS_SRC_BURST_SPEED_MIN,   0.001             //Minimum speed of an emitted particle
    ,PSYS_SRC_BURST_SPEED_MAX,   0.001             //Maximum speed of an emitted particle
    ,PSYS_SRC_ACCEL,             <0,0,0>    //Acceleration of particles each second
    ,PSYS_PART_START_COLOR,      <1,1,1>  //Starting RGB color
    ,PSYS_PART_END_COLOR,        <1,1,1>  //Ending RGB color, if INTERP_COLOR_MASK is on 
    ,PSYS_PART_START_ALPHA,      1.0            //Starting transparency, 1 is opaque, 0 is transparent.
    ,PSYS_PART_END_ALPHA,        1.0            //Ending transparency
    ,PSYS_PART_START_SCALE,      <.25,.25,.25>  //Starting particle size
    ,PSYS_PART_END_SCALE,        <.25,.25,.25>  //Ending particle size, if INTERP_SCALE_MASK is on
    ,PSYS_SRC_ANGLE_BEGIN,       1.54 //Inner angle for ANGLE patterns
    ,PSYS_SRC_ANGLE_END,         1.55 //Outer angle for ANGLE patterns
    ,PSYS_SRC_OMEGA,             <0.0,0.0,0.0>  //Rotation of ANGLE patterns, similar to llTargetOmega()
            ]);
}

generalParticleEmitterOff()
{
    llParticleSystem([]);
}

updateText()
{
    string str;
    
     if( claimed_key==NULL_KEY )
        str = "Touch to Claim Tip Jar\n";
    else
        str = claimed_name + "'s Tip Jar\n";
      
    if( total>0 )
        str+= (string)total + " donated so far.";
    else
        str+= "Empty";
    
    llSetText(str, <0,1,0>, 1);
}

default
{
    state_entry()
    {
        llRequestPermissions(llGetOwner(), PERMISSION_DEBIT );  
    }

    on_rez(integer s)
    {
        llResetScript();
    }

    run_time_permissions (integer perm)
    {
        if(perm & PERMISSION_DEBIT)
        {
            state unclaimed;     
        }
    }
}
                        

state unclaimed 
{ 
    state_entry()
    {
        if( claimed_key!=NULL_KEY )
        {
            llSay(0,"Tip jar switching back to unclaimed.");
        }   
        index = 0;
        query = llGetNotecardLine("Config",index++);
        claimed_key = NULL_KEY;
        claimed_name = "";
        total = 0;
        updateText();
    }
    
    touch_start(integer count)
    {
        integer success = FALSE;
        
        if( check_group )
        {
            if( llDetectedGroup(0) )
            {
                success = TRUE;
            }
            else
            {
                llSay(0,"Sorry, you are not in the correct group to claim this jar.");
            }
        }
        else success = TRUE;
        
        
        if( success )
        {
            claimed_key = llDetectedKey(0);
            claimed_name = llDetectedName(0);
            llInstantMessage(claimed_key,"You have claimed the tip Jar, touch again to uncliam.");
            llInstantMessage(claimed_key,"You will get " + (string)(percent*100) + "% of the tips.");
            state claimed;
        }
    }
    
    money(key giver, integer amount) {
        llSay(0, "Thanks for the " + (string)amount + "L$, " + llKey2Name(giver));
        total+=amount;
        updateText();
    }
    
    dataserver(key query_id, string data) 
    {
        if (query == query_id) 
        {
            // this is a line of our notecard
            if (data != EOF) 
            {    
                // process first line, tip price list
                if( index==1 )
                {
                    list l = llCSV2List(data);
                    list l2 = [];
                    
                    integer length = llGetListLength(l);
                    integer i;
                    for(i=0;i<length;i++)
                    {
                        l2+=[llList2Integer(l,i)];
                    }
                    

                    llSetPayPrice(llList2Integer(l2,0),l2);
                }
                // Line 2: Percent to pay to tip claimer
                else if( index==2 )
                {
                    percent = (integer)data;
                    percent/= 100;
                }
                else if( index==3 )
                {
                    timeout = (integer)data;
                }
                else if( index==4 )
                {
                    if( llToLower(data)=="group" )
                    {
                        check_group = TRUE;
                    }
                }
                query = llGetNotecardLine("Config",index++);

            } 
        }
    }
}


state claimed
{    
    state_entry()
    {
        if( percent>1 )
        {
            llInstantMessage(claimed_key, "Payback it set to more than 100%, can't claim tip jar.");
            state unclaimed;
        }
        
        updateText();
        generalParticleEmitterOn();
        llListen(CHANNEL, "", llGetOwner(), "");
        if( timeout>0 )
            llSetTimerEvent(60*timeout);
    }
    
    money(key giver, integer amount) {
        llSay(0, "Thanks for the " + (string)amount + "L$, " + llKey2Name(giver));
        total+=amount;
        llGiveMoney(claimed_key,(integer)(amount*percent));
        updateText();
    }
    
    touch_start(integer count)
    {
        if( (llDetectedKey(0)==claimed_key) || (llDetectedKey(0)==llGetOwner()) )
        {
            state unclaimed;
        }
    }
    
    timer()
    {
        state unclaimed;
    }
    
    touch_start(integer count)
    {
        if( llDetectedKey(0)==claimed_key ||
            llDetectedKey(0)==llGetOwner() )
        state unclaimed;
    }
}




