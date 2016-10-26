function totalcheck(board,row,col,value){
    if( checkRow(board,row,value) && checkCol(board,col,value) && checkCube(board,row,col,value) )
        return true;
    else
        return false;
}
function game(board){
    solution = solve(board);
    
    if(solution != -1)
        {
            
        }
}
function solve(board){
var therow, thecol;
    var soVal;
 var empties = getEmpty(board);
for(int a=0; 0<=a<empties.length;)
    {
        soVal = board[therow][thecol]++;
        var works = false;
        therow = empties[a][0];
        thecol = empties[a][1];
        while(solVal<10 && works){
            if(totalcheck(board,therow,thecol,soVal))
                {
                    works = true;
                    board[therow][thecol] = soVal;
                }
            else
                soVal++;
            
        }
        if(!works){
            board[therow][thecol]=0;
            a--;
        }           
    }
    if(a<-1)
        {
            return -1;
        }
    else{
        return board;
    }

}

function getEmpty(board){
    emptyarray = [];
    for(int i=0;i<board.length;i++)
        {
            for(int j=0;i<board[i].length;j++)
                {
                    if(board[i][j]=== 0)
                        emptyarray.push([i,j]);
                }
        }
    return emptyarray;
}

function checkRow(board,row,value){
    for(int i=0;i<board[row].length;i++){
        if value === board[row][i]
            return false;
    }
    return true;   
}

function checkCol(board,col,value){
    for(int i=0;i<board.length;i++){
        if value == board[i][col]
            return false;
    }
    return true;
}

function checkCube (board,row,col,value){
    row = getrow(board,row);
    col = getcol(board,col);
    for(int i=row; i<row+3 ; i++)
        {
                for(int j=col; j<col+3; i++){
                   if (board[i][j] === value)
                       return false;
                }
        }
    return true;
}

function getcol(board,col){
    var i = col;
    var lcol =0;
    while( i>2){
        lcol += 3;
        i -=3;
    }
    return lcol;
    
}
function getrow(board,row){
    var i = row;
    var trow = 0;
    while(i >2)
        {
            trow += 3;
            i -=3;
        }
    return trow;
}







