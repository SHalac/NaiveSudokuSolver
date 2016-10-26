$( document ).ready(function() {
   
    
    $(".cell-value").attr("maxlength", 1);
$("#solve-button").on('click',function(event){
        var array1 = [];
        var array2 = [];
   $(".cell-value").each(function(){
       var value = $(this).val();
           if(value === ''){
            array1.push(0);
           }
            else{
                array1.push(parseInt(value));
            }
    });
    
    while(array1.length)
        {
        array2.push(array1.splice(0,9));
        }
   
    var solutionArray = game(array2);
    var dsol = [];
    for(var i = 0; i < solutionArray.length; i++)
{
    dsol = dsol.concat(solutionArray[i]);
}
    var keep =0;
    $(".cell-value").each(function(){
        $(this).val(dsol[keep]);
        keep++;
    });
    
});
    

});

function totalcheck(board,row,col,value){
    if( checkRow(board,row,value) && checkCol(board,col,value) && checkCube(board,row,col,value) )
        return true;
    else
        return false;
}
function game(board){
    var solution = solve(board);
    return solution; 
}
function getEmpty(board){
    emptyarray = [];
   for(var i=0;i<board.length;i++)
        {
            for(var j=0;j<board[i].length;j++)
                {
                    if(board[i][j]=== 0)
                       emptyarray.push([i,j]);
                        
                }
        }
    return emptyarray;
}
function solve(board){
var therow, thecol, soVal,works;

 var empties = getEmpty(board);
console.log('got the empties...');
console.log(empties.length);
for(var a=0; a<empties.length; )
    {
        works = false;
        therow = empties[a][0];
       thecol =  empties[a][1];

        soVal = board[therow][thecol]+ 1;
        
        
        while(soVal<10 && !works){
            if(totalcheck(board,therow,thecol,soVal))
                {
                    works = true;
                    board[therow][thecol] = soVal; //wait.. check that  loop...no wait..
                    a++;
                }
            else{
                soVal++;
            }
        }
        if(!works){
            board[therow][thecol]=0;
            a--;
        } 
        
    }
        return board;

}



function checkRow(board,row,value){
    for(var i=0;i<board[row].length;i++){
        if (value === board[row][i])
            return false;
    }
    return true;   
}

function checkCol(board,col,value){
    for(var i=0;i<board.length;i++){
        if (value == board[i][col])
            return false;
    }
    return true;
}

function checkCube (board,row,col,value){
    row = getrow(board,row);
    col = getcol(board,col);
    for(var i=row; i<row+3 ; i++)
        {
                for(var j=col; j<col+3; j++){
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

