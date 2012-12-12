
exports.xor = function(str1, str2) {
    if (str1.length != str2.length)
        throw new Error("can only XOR things of equal length");
    var output = Buffer(str1.length);
    for (var i=0; i < str1.length; i++)
        output[i] = str1[i] ^ str2[i];
    return output;
};

exports.bufslice = function(buf, start, end) {
    if (end > buf.length)
        end = buf.length;
    return buf.slice(start, end);
}
