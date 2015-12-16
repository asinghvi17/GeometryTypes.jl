"""
Triangulate an N-Face into a tuple of triangular faces.
"""
@generated function decompose{N, FT1, FT2, O1, O2}(::Type{Face{3, FT1, O1}},
                                       f::Face{N, FT2, O2})
    @assert 3 <= N # other wise degenerate

    v = Expr(:tuple)
    append!(v.args, [:(Face{3,$FT1,$O1}(f[1]+$(-O2+O1),
                                        f[$(i-1)]+$(-O2+O1),
                                        f[$(i)]+$(-O2+O1))) for i = 3:N])
    v
end

"""
Extract all line segments in a Face.
"""
@generated function decompose{N, FT1, FT2, O1, O2}(::Type{Face{2, FT1, O1}},
                                       f::Face{N, FT2, O2})
    @assert 2 <= N # other wise degenerate

    v = Expr(:tuple)
    append!(v.args, [:(Face{2,$FT1,$O1}(f[$(i)]+$(-O2+O1),
                                        f[$(i+1)]+$(-O2+O1))) for i = 1:N-1])
    # connect vertices N and 1
    push!(v.args, :(Face{2,$FT1,$O1}(f[$(N)]+$(-O2+O1),
                                     f[$(1)]+$(-O2+O1)))) # not enough dollars
    v
end

"""
Decompose an N-Simplex into a tuple of Simplex{3}
"""
@generated function decompose{N, T1, T2}(::Type{Simplex{3, T1}},
                                       f::Simplex{N, T2})
    @assert 3 <= N # other wise degenerate

    v = Expr(:tuple)
    append!(v.args, [:(Simplex{3,$T1}(f[1],
                                        f[$(i-1)],
                                        f[$i])) for i = 3:N])
    v
end

# less strict version of above that preserves types
decompose{N, T}(::Type{Simplex{3}}, f::Simplex{N, T}) = decompose(Simplex{3,T}, f)

"""
Decompose an N-Simplex into tuple of Simplex{2}
"""
@generated function decompose{N, T1, T2}(::Type{Simplex{2, T1}},
                                       f::Simplex{N, T2})
    @assert 2 <= N # other wise degenerate

    v = Expr(:tuple)
    append!(v.args, [:(Simplex{2,$T1}(f[$(i)],
                                        f[$(i+1)])) for i = 1:N-1])
    # connect vertices N and 1
    push!(v.args, :(Simplex{2,$T1}(f[$(N)],
                                     f[$(1)])))
    v
end

# less strict version of above that preserves types
decompose{N, T}(::Type{Simplex{2}}, f::Simplex{N, T}) = decompose(Simplex{2,T}, f)

"""
Decompose an N-Simplex into a tuple of Simplex{1}
"""
@generated function decompose{N, T1, T2}(::Type{Simplex{1, T1}},
                                       f::Simplex{N, T2})
    v = Expr(:tuple)
    append!(v.args, [:(Simplex{1,$T1}(f[$i])) for i = 1:N])
    v
end
# less strict version of above
decompose{N, T}(::Type{Simplex{1}}, f::Simplex{N, T}) = decompose(Simplex{1,T}, f)

"""
Get decompose a `HyperRectangle` into points.
"""
@generated function decompose{N,T1<:FixedVector,T2}(::Type{T1},
                                 rect::HyperRectangle{N, T2})
    # The general strategy is that since there are a deterministic number of
    # points, we can generate all points by looking at the binary increments.
    v = Expr(:tuple)
    for i = 0:(2^N-1)
        ex = Expr(:call, T1)
        for j = 0:(N-1)
            n = 2^j
            # the macro hygeine is a little wonky here but this
            # translates to rect.(Int((i&n)/n+1))[Int(j+1)]
            push!(ex.args, Expr(:ref,Expr(:.,:rect,Int((i&n)/n+1)),Int(j+1)))
        end
        push!(v.args, ex)
    end
    v
end

function decompose{P}(T::Type{P},r::SimpleRectangle)
   P[P(r.x, r.y),
    P(r.x, r.y + r.h),
    P(r.x + r.w, r.y + r.h),
    P(r.x + r.w, r.y)]
end

function decompose{PT}(T::Type{Point{3, PT}},p::Pyramid)
    T[T(PT(0),PT(0),p.middle[3]+p.length*PT(0)),
      T(p.width/2, p.width/2, PT(0)),
      T(-p.width/2, p.width/2, PT(0)),
      T(p.width/2, -p.width/2, PT(0)),
      T(-p.width/2, -p.width/2, PT(0))]
end

function decompose{PT<:AbstractFloat}(T::Type{Point}, p::Pyramid{PT})
    decompose(Point{3,PT},p)
end

function decompose{PT}(T::Type{Point}, p::Pyramid{PT})
    decompose(Point{3,Float64},p)
end

function decompose{ET}(T::Type{Point{3, ET}}, q::Quad)
   T[q.downleft,
    q.downleft + q.height,
    q.downleft + q.width + q.height,
    q.downleft + q.width]
end
