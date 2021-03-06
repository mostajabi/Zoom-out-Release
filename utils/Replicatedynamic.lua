local Replicatedynamic, parent = torch.class('nn.Replicatedynamic','nn.Module')

function Replicatedynamic:__init(dim, downsample, ndim)
   parent.__init(self)
   --self.nfeatures = nf
   self.dim = dim or 1
   self.ndim = ndim
   self.downsample = downsample or 1
   assert(self.dim > 0, "Can only replicate across positive integer dimensions.")
end

function Replicatedynamic:updateOutput(input)
   self.nfeatures = input[2]:size(3)/self.downsample
   self.dim = self.dim or 1 --backwards compatible
   input = input[1]
   assert(
      self.dim <= input:dim()+1,
      "Not enough input dimensions to replicate along dimension " ..
      tostring(self.dim) .. ".")
   local batchOffset = self.ndim and input:dim() > self.ndim and 1 or 0
   local rdim = self.dim + batchOffset
   local sz = torch.LongStorage(input:dim()+1)
   sz[rdim] = self.nfeatures
   for i = 1,input:dim() do
      local offset = 0
      if i >= rdim then
         offset = 1
      end
      sz[i+offset] = input:size(i)
   end
   local st = torch.LongStorage(input:dim()+1)
   st[rdim] = 0
   for i = 1,input:dim() do
      local offset = 0
      if i >= rdim then
         offset = 1
      end
      st[i+offset] = input:stride(i)
   end
   self.output:set(input:storage(),input:storageOffset(),sz,st)
   return self.output
end

function Replicatedynamic:updateGradInput(input, gradOutput)
   local input1 = input[1];
   if torch.type(self.gradInput)=='table' then
		self.gradInput=self.gradInput[1]
	end
   self.gradInput:resizeAs(input1):zero()
   local batchOffset = self.ndim and input1:dim() > self.ndim and 1 or 0
   local rdim = self.dim + batchOffset
   local sz = torch.LongStorage(input1:dim()+1)
   sz[rdim] = 1
   for i = 1,input1:dim() do
      local offset = 0
      if i >= rdim then
         offset = 1
      end
      sz[i+offset] = input1:size(i)
   end
   local gradInput = self.gradInput:view(sz)
   gradInput:sum(gradOutput, rdim)
   self.gradInput={self.gradInput,torch.Tensor():typeAs(input[2]):resizeAs(input[2]):zero()}
   return self.gradInput
end
