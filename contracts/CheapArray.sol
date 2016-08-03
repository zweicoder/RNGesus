// http://ethereum.stackexchange.com/questions/3373/how-to-clear-large-arrays-without-blowing-the-gas-limit
library CheapArray {
    uint n;

    function insertAll(bytes[] storage elems, bytes[] values) {
        for (uint i=0; i < values.length; i++) {
            insert(elems, values[i])
        }
    }

    function insert(bytes[] elems, bytes value) {
        if(n == elems.length) {
            n = elems.push(value);
            return;
        }
        elems[n] = value;
    }

    function clear() {
        n = 0;
    }
}