LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

-- 16-bit Linear Feedback Shift Register for pseudo-random number generation
ENTITY lfsr_rng IS
    PORT (
        clk    : IN STD_LOGIC;
        reset1  : IN STD_LOGIC;
        enable : IN STD_LOGIC;  -- Enable to get new random value
        seed   : IN STD_LOGIC_VECTOR(15 DOWNTO 0);  -- Initial seed (must not be all zeros)
        rand_out : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
    );
END lfsr_rng;

ARCHITECTURE Behavioral OF lfsr_rng IS
    SIGNAL lfsr_reg : STD_LOGIC_VECTOR(15 DOWNTO 0) := "1010110011100001";  -- Default non-zero seed
    SIGNAL feedback : STD_LOGIC;
BEGIN
    -- Feedback polynomial for 16-bit LFSR: x^16 + x^15 + x^13 + x^4 + 1
    -- This gives maximum length sequence (65535 values before repeating)
    feedback <= lfsr_reg(15) XOR lfsr_reg(14) XOR lfsr_reg(12) XOR lfsr_reg(3);
    
    PROCESS(clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF reset1 = '1' THEN
                -- Load seed (ensure it's not all zeros)
                IF seed = x"0000" THEN
                    lfsr_reg <= "1010110011100001";  -- Default seed if invalid
                ELSE
                    lfsr_reg <= seed;
                END IF;
            ELSIF enable = '1' THEN
                -- Shift and insert feedback bit
                lfsr_reg <= lfsr_reg(14 DOWNTO 0) & feedback;
            END IF;
        END IF;
    END PROCESS;
    
    rand_out <= lfsr_reg;
    
END Behavioral;
