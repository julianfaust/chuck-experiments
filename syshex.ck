
public class Syshex extends Chubgraph
{
    int mess[17];
    [0xF0,0x00,0x01,0x61,0x03,0x04,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xF7] @=> mess;
    
    int dec;
    int bin[7];
 //   [0,0,0,0,0,0,0] @=> bin;
    
    int lmap[];
    [0,1,2,3,4,5,6,7
    ,14,15,16,17,18,19,20,21
    ,28,29,30,31,32,33,34,35
    ,42,43,44,45,46,47,48,49
    ,56,57,58,59,60,61,62,63
    ,8,9,11,12,13,50,51,53
    ,22,23,25,26,27,64,65,67
    ,36,37,39,40,41,54,55,68] @=> lmap;
    
    int ltrack[64];
    
    Event ntrack[64];
    for(int i;i<64;i++)
        null => ntrack[i];
    

    
    int params[10];

    
    MidiIn min;
    MidiOut mout;
    MidiMsg msg;
    
    Envelope env => outlet;
            
    10::ms => env.duration;
    1 => env.keyOn;
    0.1 => env.gain;
    0 => int count;
    
    int active[0];
    

    fun void open(int device)
    {
        if(!mout.open(device) || !min.open(device)) me.exit();
        <<< "Opened ", mout.num(), "->", mout.name(), " for lights" >>>;
        this.sendhex();
    }
    
    fun void addVoice(int m)
    {
        SinOsc osc => Envelope e => this.env;
        Std.mtof(m+36) => osc.freq;
        10::ms => e.duration;
        1 => e.keyOn;
        Event ev @=> ntrack[m];
        ntrack[m] => now;
        1 => e.keyOff;
        e.duration() => now;
        osc !=> e;
        e !=> env;
        
    }
    fun void endVoice(int m)
    {
        if (ntrack[m] != null) ntrack[m].broadcast();
        null => ntrack[m];
        <<< m >>>;
    }

fun void setdec(int decin)
{
    decin => dec;
    
    for(6 => int i;i>=0;1-=>i)
    {
        if(dec >= (Math.pow(2,i) $ int))
        {
            1 => bin[i];
            dec - (Math.pow(2,i) $ int) => dec;
        }
        else 0 => bin[i];
    }
    
 //   <<< bin[0], " ", bin[1], " ",bin[2], " ",bin[3], " ",bin[4], " ",bin[5] >>>;
}

    fun void setn(int n)
    {
        n / 128 => int div;
        n % 128 => int mod;
        for(0 => int i;i<div;1+=>i)
        {
            127 => mess[6+i];
        }
        mod => mess[6+div];
    
        
    }
    fun void setrand()
    {
        setn(Math.rand2(0,128*9));
    }
    fun int transpose(int m)
    {
        return (m % 8) * 8 + m / 8;
    }
    
    fun void flipbit(int bytenum, int bitnum)
    {
        setdec(mess[6+bytenum]);

        1 - bin[bitnum] => bin[bitnum];
     //               <<< bin[0], " ", bin[1], " ",bin[2], " ",bin[3], " ",bin[4], " ",bin[5], " ",bin[6]>>>;

        0 => mess[6+bytenum];
        for(0=> int i;i<7;1+=>i)
            if(bin[i] == 1)
                Math.pow(2,i) $ int +=> mess[6+bytenum];
    }
    
    fun void multiflip(int arr[])
    {
        int mpt;
        for(0 => int i;i<arr.size();1+=>i)
        {
            this.lmap[arr[i]] => mpt;
            this.flipbit(mpt / 7,mpt % 7);
        }
        if(arr.size() > 6)
        {
            //<<< "hexmode" >>>;
            this.sendhex();
        }
        else
        {
            //  <<< "notemode" >>>;
            144 => msg.data1;
            for(0 => int i;i<arr.size();1+=>i)
            {
                transpose(arr[i]) => msg.data2;
                if(ltrack[arr[i]] == 0)
                {
                    64 => msg.data3;
                }
                else 
                {
                    0 => msg.data3;
                }
                1 - ltrack[arr[i]] => ltrack[arr[i]];
                mout.send(msg);
            }
        }
    }
    fun void setall(int arr64[])
    {
        int arrflex[0];
        for(0=> int i;i<arr64.size();1+=>i)
        {
            if(ltrack[arr64[i]] != arr64[i])
            {
                arrflex << transpose(i);
            }
        }
        multiflip(arrflex);
        <<< arrflex.size() >>>;
    }
    fun void setOn(int arr[])
    {
        int arrflex[0];
        for(int i;i<arr.size();i++)
        {
            if(ltrack[transpose(arr[i])] == 0)
                arrflex << transpose(arr[i]);
        }
        multiflip(arrflex);
    }
    fun void setOff(int arr[])
    {
        int arrflex[0];
        for(int i;i<arr.size();i++)
            if(ltrack[transpose(arr[i])] != 0)
                arrflex << transpose(arr[i]);
        multiflip(arrflex);
    }   

    fun void sendhex()
    {
        for(0 => int i;i<17/3+1;1+=>i)
        {
            mess[3*i] => msg.data1;
            if(3*i+1<17)
                mess[3*i+1] => msg.data2;
            if(3*i+2<17)
                mess[3*i+2] => msg.data3;
            mout.send(msg);
        }
    }
    fun void flightOn(int m)
    {
        this.setOn([m]);
    }
    fun void flightOff(int m)
    {
        this.setOff([m]);
    }
    
    fun void fkeyOn(int m)
    {
        spork ~ addVoice(m);
    }
    fun void fkeyOff(int m)
    {
        this.endVoice(m);
    }
    fun void fbutOn(int m)
    {
        <<< m, " button" >>>;
    }    
    fun void fctrl(int n,int val)
    {
    }    
    
    fun void getmidi()
    {
        while(true)
        {

            min => now;
            while(min.recv(msg))
            {
                if(msg.data1 == 144)
                {
                    if(msg.data2 < 64)
                    {
                        if(msg.data3 > 0)
                        {
                            this.flightOn(msg.data2);
                            this.fkeyOn(msg.data2);
                        }
                        else 
                        {
                            this.flightOn(msg.data2);
                            this.fkeyOff(msg.data2);
                        }
                    }
                    else fbutOn(msg.data2);
                    
                }
                else if(msg.data1 == 176 && msg.data2 < 10)
                {
                    msg.data3 => params[msg.data2];
                    fctrl(msg.data2,msg.data3);
                }
            }
        }
    }
    

    
   
}