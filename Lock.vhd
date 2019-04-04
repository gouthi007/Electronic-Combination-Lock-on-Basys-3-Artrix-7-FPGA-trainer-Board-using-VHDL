library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
--use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity LockTopLevel is
    Port ( InClock : in STD_LOGIC;
           AnodeDriver : out STD_LOGIC_VECTOR (3 downto 0);
           SevenSegDriver : out STD_LOGIC_VECTOR (6 downto 0);
           PushL : in STD_LOGIC;
           PushU : in STD_LOGIC;
           PushD : in STD_LOGIC;
           PushR : in STD_LOGIC;
           PushC : in STD_LOGIC;
           DotLED : out STD_LOGIC_VECTOR (15 downto 0);
           Switch : in STD_LOGIC_VECTOR (3 downto 0));
end LockTopLevel;

architecture Behavioral of LockTopLevel is

signal ClkToggle : STD_LOGIC := '0'; -- the clock toggling signal

signal ClkUsed : std_logic := '0'; -- 100Hz clock generated manually

signal Bgen, B0, B1, B2, B3 : STD_LOGIC_VECTOR ( 3 downto 0 );

signal LTemp, u, d, r, c : std_logic := '0'; 

signal State : integer range 0 to 2;

signal CurrentS, NextS : integer range 0 to 2;

signal Valid : integer range 0 to 2;

signal AttemptCount : STD_LOGIC_VECTOR ( 1 downto 0 );

signal TimeConstraint : STD_LOGIC_VECTOR ( 7 downto 0 ) := x"00";

signal CounterSec : STD_LOGIC_VECTOR ( 19 downto 0);

signal sevensegselect : STD_LOGIC_VECTOR ( 1 downto 0);

signal CounterOneSec : STD_LOGIC_VECTOR ( 27 downto 0):= x"0000000";

signal OneSecEnable : STD_LOGIC;

signal Wait30Sec : STD_LOGIC := '0';  

signal t1, t2, t3, t4 : STD_LOGIC := '0';

signal Display, Display2 : STD_LOGIC_VECTOR ( 27 downto 0 ) ;
 

begin

--100Hz  clock
-- reduced clock 
process ( InClock )
variable count : STD_LOGIC_VECTOR ( 31 downto 0 ) := x"00000000"; -- variable needed for counter       
begin
     if ( rising_edge ( InClock ) ) then
        count := count + 1;  
                if (( count ) = x"0007A120" ) then
                ClkToggle <= NOT ClkToggle; -- toggling signal toogles its value
                count := x"00000000"; -- counter resets to 0
                end if;
     end if;
end process;

ClkUsed <= ClkToggle; -- the clock of 100Hz frequency that has been generated

Bgen <= Switch(3 downto 0);

--pushing the values of the code in order 
process (PushL,PushU, PushD, PushR, InClock)
begin 
    if (rising_edge (InClock)) then
    if (PushL = '1') then 
           B3 <= Bgen;
           LTemp <= '1';
           end if;
    if (PushU = '1') then 
           B2 <= Bgen;
           LTemp <= '1';
           end if;
    if (PushD = '1') then 
           B1 <= Bgen;
           LTemp <= '1';
           end if;
    if (PushR = '1') then 
           B0 <= Bgen;
           LTemp <= '0';
            end if;
           end if;
end process;


-- assigning the next state to the current state

process(InClock) 
begin
    if(rising_edge(InClock)) then 
 CurrentS <= NextS; 
end if; 
end process;



--checking the code and setting the state
process (InClock, PushC)
begin
if (rising_edge (InClock)) then
    if (PushC = '1') then
     -- if (TimeConstraint >=x"1" and TimeConstraint < x"1E") then
      if (Valid = 1) then 
        if (B3 = "1000" and B2 = "0101" and B1 = "0001" and B0 = "0011") then
        NextS <= 1;
        else
        NextS <= 0;
        end if;
        elsif (Valid = 0) then
        --elsif( TimeConstraint >= x"1E") then
        NextS <= 2;
        end if;
     end if;
end if;
end process;


--lighting the LED if it is unlocked
process (InClock)
begin
    if (CurrentS = 1) then
    DotLED <= "1111111111111111";
    else 
    DotLED <= "0000000000000000";
    end if;
end process;



process( InClock, PushC) 
begin
if( rising_edge (InClock)) then
    t1 <= PushC;
    t2<= t1;
    t3 <= t2;
    if ( CounterSec = "11111111111111111111" ) then
    CounterSec <= "00000000000000000000";
    else
    CounterSec <= CounterSec + 1;
    end if;
end if;    
end process;

sevensegselect <= CounterSec(19 downto 18);
t4  <= t1 and t2 and (not t3);


process ( t4)
begin
if(t4 = '1') then
Display2 <= Display;
end if;
end process;



-- setting the values of the sevenseg display

process ( CurrentS)
begin
case CurrentS is
when 1 => 
Display ( 27 downto 21) <= "1000001";
Display ( 20 downto 14) <= "1101010";
Display ( 13 downto 7) <=  "1110001";
Display ( 6 downto 0) <= "0110001";
when 0 =>
Display ( 27 downto 21) <= "1110001";
Display ( 20 downto 14) <=  "0000001"; 
Display ( 13 downto 7) <=  "0110001";
Display ( 6 downto 0) <=  "1111111";

when 2 =>
Display ( 27 downto 21) <= "0011000"; 
Display ( 20 downto 14) <= "0001000";
Display ( 13 downto 7) <=  "1000001";
Display ( 6 downto 0) <= "0100100";

end case;
end process;





--add the anode driver and the seven seg display for the respective things 
--thanos start
--process (ClkUsed)
--begin
  --  case (State) is
    --    when 
        

process (sevensegselect, PushC, InClock)

-- select line for the 4 seven segment displays

begin
if (rising_edge (InClock)) then
            --if (pushbutton = '1' and lastbuttonstate = '0') then --checking every time the button is pressed and perfrorming the latching operation of the LEDs
        if (PushC = '1') then
            c <= '1';
            case sevensegselect is
                when "00" => SevenSegDriver <= Display2 ( 27 downto 21); --UnLC
                AnodeDriver <= "0111";--turning on the leftmost 7 segment display
                
                when "01" => SevenSegDriver <= Display2 ( 20 downto 14); --UnLC
                AnodeDriver <= "1011";--turning on the leftmost 7 segment display
                
                when "10" => SevenSegDriver <= Display2 ( 13 downto 7); --UnLC
                AnodeDriver <= "1101";--turning on the leftmost 7 segment display
                
                when "11" => SevenSegDriver <= Display2 ( 6 downto 0); --UnLC
                AnodeDriver <= "1110";--turning on the leftmost 7 segment display
                
            end case;
      
            end if;
        --lastbuttonstate <= pushbutton;
        end if;
   
end process;




--thanos end



--one second enable

process(InClock)
begin
if(rising_edge(InClock)) then 
 CounterOneSec <= CounterOneSec + x"0000001";
 if(CounterOneSec >= x"0000003") then 
  CounterOneSec <= x"0000000";
 end if;
end if;
end process;
OneSecEnable <= '1' when CounterOneSec = x"0003" else '0';

--sec counter


process( InClock, LTemp)
begin   
if(rising_edge(InClock)) then
if(OneSecEnable <= '1') then
       -- if ( LTemp = '1' and TimeConstraint < x"1E") then
        if (LTemp = '1' ) then
        TimeConstraint <= TimeConstraint + x"1";
        
        if (TimeConstraint <= x"1E" ) then
        Valid <= 1;
        end if;
        
        elsif(LTemp = '1' and TimeConstraint >= x"1E") then
        Valid <= 0;
        
        elsif( c = '1') then
        TimeConstraint <= x"00";
        
        elsif(c = '1') then
        Valid <= 0;
    end if;
  
end if;
end if;
end process;


end Behavioral;
