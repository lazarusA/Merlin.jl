type Model
    wordfun
    charfun
    sentfun
end

function Model{T}(wordembeds::Vector{Vector{T}}, charembeds::Vector{Vector{T}}, ntags::Int)
    x = Var()
    y = charembeds(x)
    y = window(y, (50,), pads=(20,), strides=(10,))
    y = Linear(T,50,50)(y)
    y = max(y, 2)
    charfun = compile(y, x)

    w = Var() # word vector
    c = Var() # chars vector
    y = concat(1, w, c)
    y = window(y, (750,), pads=(300,), strides=(150,))
    y = Linear(T,750,300)(y)
    y = relu(y)
    y = Linear(T,300,ntags)(y)
    sentfun = compile(y, w, c)

    Model(wordembeds, charfun, sentfun)
end

function (m::Model)(tokens::Vector{Token})
    wordvec = map(t -> t.word, tokens)
    wordvec = reshape(wordvec, 1, length(wordvec))
    wordmat = m.wordfun(Var(wordvec))

    charvecs = map(tokens) do t
        #Var(zeros(Float32,50,1))
        charvec = reshape(t.chars, 1, length(t.chars))
        m.charfun(Var(charvec))
    end
    charmat = concat(2, charvecs)
    m.sentfun(wordmat, charmat)
end
