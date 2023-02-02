pragma circom 2.0.0;

/* 
examples:
 non-zero: in0: 2, in1: 3
 inverse <== 1 / (in0 - in1);
   inverse = 1 / (2 - 3) = 1 / -1 = -1
 inverse * (in0 - in1) === 1;
   -1 * (2 - 3) = -1 * -1 = 1 : OK

  zero: in0: 2, in1: 2
  inverse <== 1 / (in0 - in1);
    inverse = 1 / (2 - 2) = 1 / 0 = 0
  inverse * (in0 - in1) === 1;
    0 * (2 - 2) = 0 * 0 = 0 != 1 : FAIL  
*/
template NonEqual(){
    signal input in0;
    signal input in1;
    // both inputs arent equal to each other
    signal inverse;
    inverse <-- 1 / (in0 - in1);
    inverse * (in0 - in1) === 1;
}

template Distinct(n) {
    signal input in[n];
    component nonEqual[n][n];
    for (var i = 0; i < n; i++) {
        for (var j = 0; j < i; j++) {
            if (i != j) {
                nonEqual[i][j] = NonEqual();
                nonEqual[i][j].in0 <== in[i];
                nonEqual[i][j].in1 <== in[j];
            }
        }
    }
}

// Enforce that 0 <= in < 16, that it fits in 4 bits
template Bits4(){
    signal input in;
    signal bits[4];
    var bitsum = 0;
    for (var i = 0; i < 4; i++) {
        // whenever the last bit isnt set, bits[i] must be zero and the bitsum will be zero
        // whenever the last bit is set the bitsum will be 2 ** i
        /* 
            Expample for in = 12:
            bits[0] = (12 >> 0) & 1 = 0
            bits[1] = (12 >> 1) & 1 = 0
            bits[2] = (12 >> 2) & 1 = 1
            bits[3] = (12 >> 3) & 1 = 1
            bitsum = 
              [0]: 0 + (2 ** 0) * 0 + 
              [1]: 0 + (2 ** 1) * 0 + 
              [2]: 0 + (2 ** 2) * 1 + 
              [3]: 4 + (2 ** 3) * 1 = 12
        */
        bits[i] <-- (in >> i) & 1;
        bits[i] * (bits[i] - 1) === 0;
        // bitsum = (bitsum) + (2 ** i) * (bits[i]);
        bitsum = bitsum + 2 ** i * bits[i];
    }

    bitsum === in;
}

// Enforce that 1 <= in <= 9
template OneToNine() {
    signal input in;
    component lowerBound = Bits4();
    component upperBound = Bits4();
    // if the input should be between 1 and 9, then we can use the same logic as for 0 <= in < 16
    // for lower bound: (>=) 1 - 1 = 0   
    // for upper bound: (<= 9) + 6 = 15
    lowerBound.in <== in - 1;
    upperBound.in <== in + 6;
}

template Sudoku(n) {
    // solution is a 2D array: indices are (row_i, col_i)
    signal input solution[n][n];
    // puzzle is the same, but a zero indicates a blank
    signal input puzzle[n][n];

    // ensure that each solution # is in range
    component inRange[n][n];
    for (var i = 0; i < n; i++) {
        for (var j = 0; j < n; j++) {
            inRange[i][j] = OneToNine();
            inRange[i][j].in <== solution[i][j];
        }
    }

    // ensure that in every location the puzzle should be blank or the solution should be the same as the puzzle (agreement)
    for (var i = 0; i < n; i++) {
        for (var j = 0; j < n; j++) {
            // puzzle_cell * (puzzle_cell - solution_cell) === 0;
            // if puzzle_cell is zero, then the solution must be zero
            // otherwise the solution must be equal to the puzzle so the solution must be zero as well
            puzzle[i][j] * (puzzle[i][j] - solution[i][j]) === 0; 
        }
    }

    // ensure uniqueness of each row
    component distinct[n];
    for (var i = 0; i < n; i++) { // i is row index
        // distinctness of each row
        distinct[i] = Distinct(n); 
        for (var j = 0; j < n; j++) { // j is column index
            distinct[i].in[j] <== solution[i][j];
        }
    }

}

// puzzle is public, solution is private
component main {public[puzzle]} = Sudoku(9);